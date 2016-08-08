/*************************************************************************
 *
 * REALM CONFIDENTIAL
 * __________________
 *
 *  [2016] Realm Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of Realm Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to Realm Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Realm Incorporated.
 *
 **************************************************************************/

import Cocoa
import RealmSwift

private let toDoCellIdentifier = "ToDoItemCell"
private let toDoCellPrototypeIdentifier = "ToDoItemCellPrototype"

class ToDoListViewController: NSViewController {

    @IBOutlet var tableView: NSTableView!
    @IBOutlet var topConstraint: NSLayoutConstraint?

    private var items = try! Realm().objects(ToDoList.self).first!.items

    private var notificationToken: NotificationToken?
    private var skipNotification = false
    private var reloadOnNotification = false

    private let prototypeCell = PrototypeToDoItemCellView(identifier: toDoCellPrototypeIdentifier)

    private var currentlyEditingCellView: ToDoItemCellView?

    private var currentlyMovingRowView: NSTableRowView?
    private var currentlyMovingRowSnapshotView: SnapshotView?
    private var movingStarted = false

    private var autoscrollTimer: NSTimer?

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let notificationCenter = NSNotificationCenter.defaultCenter()

        // Handle window resizing to update table view rows height
        notificationCenter.addObserver(self, selector: #selector(windowDidResize), name: NSWindowDidResizeNotification, object: view.window)
        notificationCenter.addObserver(self, selector: #selector(windowDidResize), name: NSWindowDidEnterFullScreenNotification, object: view.window)
        notificationCenter.addObserver(self, selector: #selector(windowDidResize), name: NSWindowDidExitFullScreenNotification, object: view.window)

        setupNotifications()
        setupGestureRecognizers()
    }

    private func setupNotifications() {
        notificationToken = items.addNotificationBlock { changes in
            if self.skipNotification {
                self.skipNotification = false
                self.reloadOnNotification = true
                return
            } else if self.reloadOnNotification {
                self.tableView.reloadData()
                self.reloadOnNotification = false
                return
            }

            // FIXME: Hack to work around sync possibly pulling in a new list.
            // Ideally we'd use ToDoList with primary keys, but those aren't currently supported by sync.
            let realm = self.items.realm!
            let lists = realm.objects(ToDoList.self)
            let hasMultipleLists = lists.count > 1

            if hasMultipleLists {
                self.items = lists.first!.items

                defer {
                    // Append all other items while deleting their lists, in case they were created locally before sync
                    try! realm.write {
                        while lists.count > 1 {
                            self.items.appendContentsOf(lists.last!.items)
                            realm.delete(lists.last!)
                        }
                    }

                    // Resubscribe to notifications
                    self.setupNotifications()
                }
            }

            switch changes {
            case .Initial:
                self.tableView.reloadData()
            case .Update(_, let deletions, let insertions, let modifications):
                self.tableView.beginUpdates()
                self.tableView.removeRowsAtIndexes(deletions.toIndexSet(), withAnimation: .EffectFade)
                self.tableView.insertRowsAtIndexes(insertions.toIndexSet(), withAnimation: .EffectFade)
                self.tableView.reloadDataForRowIndexes(modifications.toIndexSet(), columnIndexes: NSIndexSet(index: 0))
                self.tableView.endUpdates()

                self.updateTableViewHeightOfRows(modifications.toIndexSet())
            case .Error(let error):
                fatalError(String(error))
            }
        }
    }

    private func skipNextNotification() {
        skipNotification = true
        reloadOnNotification = false
    }

    private func setupGestureRecognizers() {
        let pressGestureRecognizer = NSPressGestureRecognizer(target: self, action: #selector(handlePressGestureRecognizer))
        let panGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer))

        for recognizer in [pressGestureRecognizer, panGestureRecognizer] {
            recognizer.delegate = self
            tableView.addGestureRecognizer(recognizer)
        }
    }

    private dynamic func windowDidResize(notification: NSNotification) {
        updateTableViewHeightOfRows()
    }

    private func updateTableViewHeightOfRows(indexes: NSIndexSet? = nil) {
        // noteHeightOfRows animates by default, disable this
        NSView.animateWithDuration(0, animations: {
            self.tableView.noteHeightOfRowsWithIndexesChanged(indexes ?? NSIndexSet(indexesInRange: NSRange(0...self.tableView.numberOfRows)))
        })
    }

}

// MARK: Actions

extension ToDoListViewController {

    @IBAction func newToDo(sender: AnyObject?) {
        try! items.realm?.write {
            self.items.insert(ToDoItem(), atIndex: 0)
        }

        skipNextNotification()

        NSView.animateWithDuration(0.2, animations: {
            NSAnimationContext.currentContext().allowsImplicitAnimation = false // prevents NSTableView autolayout issues
            self.tableView.insertRowsAtIndexes(NSIndexSet(index: 0), withAnimation: .EffectGap)
        }) {
            self.tableView.viewAtColumn(0, row: 0, makeIfNecessary: false)?.becomeFirstResponder()
            self.view.window?.toolbar?.validateVisibleItems()
        }
    }

    override func validateToolbarItem(theItem: NSToolbarItem) -> Bool {
        if theItem.action == #selector(newToDo) && currentlyEditingCellView != nil {
            return false
        }

        return true
    }

}

// MARK: Reordering

extension ToDoListViewController {

    var reordering: Bool {
        return currentlyMovingRowView != nil
    }

    private func beginReorderingRow(row: Int, screenPoint point: NSPoint) {
        currentlyMovingRowView = tableView.rowViewAtRow(row, makeIfNecessary: false)

        if currentlyMovingRowView == nil {
            return
        }

        currentlyMovingRowSnapshotView = SnapshotView(sourceView: currentlyMovingRowView!)
        currentlyMovingRowView!.alphaValue = 0

        currentlyMovingRowSnapshotView?.frame.origin.y = view.convertPoint(point, fromView: nil).y - currentlyMovingRowSnapshotView!.frame.height / 2
        view.addSubview(currentlyMovingRowSnapshotView!)

        NSView.animateWithDuration(0.2, animations: {
            let frame = self.currentlyMovingRowSnapshotView!.frame
            self.currentlyMovingRowSnapshotView!.frame = frame.insetBy(dx: -frame.width * 0.02, dy: -frame.height * 0.02)
        })

        movingStarted = false
    }

    private func handleReorderingForScreenPoint(point: NSPoint) {
        if let snapshotView = currentlyMovingRowSnapshotView {
            snapshotView.frame.origin.y = snapshotView.superview!.convertPoint(point, fromView: nil).y - snapshotView.frame.height / 2
        }

        let sourceRow = tableView.rowForView(currentlyMovingRowView!)
        let targetRow: Int

        let pointInTableView = tableView.convertPoint(point, fromView: nil)

        if pointInTableView.y < tableView.bounds.minY {
            targetRow = 0
        } else if pointInTableView.y > tableView.bounds.maxY {
            targetRow = tableView.numberOfRows - 1
        } else {
            targetRow = tableView.rowAtPoint(pointInTableView)
        }

        if targetRow >= 0 && targetRow != sourceRow  {
            try! items.realm?.write {
                let item = items[sourceRow]
                items.removeAtIndex(sourceRow)
                items.insert(item, atIndex: targetRow)
            }

            skipNextNotification()

            tableView.moveRowAtIndex(sourceRow, toIndex: targetRow)
        }
    }

    private func endReordering() {
        NSView.animateWithDuration(0.2, animations: { 
            self.currentlyMovingRowSnapshotView?.frame = self.view.convertRect(self.currentlyMovingRowView!.frame, fromView: self.tableView)
        }) {
            self.currentlyMovingRowView?.alphaValue = 1
            self.currentlyMovingRowView = nil

            self.currentlyMovingRowSnapshotView?.removeFromSuperview()
            self.currentlyMovingRowSnapshotView = nil

            self.updateColors()
        }
    }

    private dynamic func handlePressGestureRecognizer(recognizer: NSPressGestureRecognizer) {
        switch recognizer.state {
        case .Began:
            beginReorderingRow(tableView.rowAtPoint(recognizer.locationInView(tableView)), screenPoint: recognizer.locationInView(nil))
        case .Ended:
            endReordering()
        case .Cancelled:
            // Handle the case when press recognizer is canceled while pan wasn't started
            if !movingStarted {
                endReordering()
            }
        default:
            break
        }
    }

    private dynamic func handlePanGestureRecognizer(recognizer: NSPressGestureRecognizer) {
        switch recognizer.state {
        case .Began:
            movingStarted = true
            startAutoscrolling()
        case .Changed:
            handleReorderingForScreenPoint(recognizer.locationInView(nil))
        case .Ended:
            endReordering()
            stopAutoscrolling()
        default:
            ()
        }
    }

    private func startAutoscrolling() {
        guard autoscrollTimer == nil else {
            return
        }

        autoscrollTimer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(handleAutoscrolling), userInfo: nil, repeats: true)
    }

    private dynamic func handleAutoscrolling() {
        if let event = NSApp.currentEvent {
            if tableView.autoscroll(event) {
                handleReorderingForScreenPoint(event.locationInWindow)
            }
        }
    }

    private func stopAutoscrolling() {
        autoscrollTimer?.invalidate()
        autoscrollTimer = nil
    }

}

// MARK: NSGestureRecognizerDelegate

extension ToDoListViewController: NSGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: NSGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: NSGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(gestureRecognizer: NSGestureRecognizer) -> Bool {
        switch gestureRecognizer {
        case is NSPressGestureRecognizer:
            let targetRow = tableView.rowAtPoint(gestureRecognizer.locationInView(tableView))

            guard targetRow >= 0, let cellView = tableView.viewAtColumn(0, row: targetRow, makeIfNecessary: false) as? ToDoItemCellView else {
                return false
            }

            return !cellView.completed
        case is NSPanGestureRecognizer:
            return reordering
        default:
            return true
        }
    }

}

// MARK: NSTableViewDataSource

extension ToDoListViewController: NSTableViewDataSource {

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return items.count
    }

}

// MARK: NSTableViewDelegate

extension ToDoListViewController: NSTableViewDelegate {

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView: ToDoItemCellView

        if let view = tableView.makeViewWithIdentifier(toDoCellIdentifier, owner: self) as? ToDoItemCellView {
            cellView = view
        } else {
            cellView = ToDoItemCellView(identifier: toDoCellIdentifier)
        }

        cellView.configureWithToDoItem(items[row])
        cellView.backgroundColor = colorForRow(row)
        cellView.delegate = self

        return cellView
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if let cellView = currentlyEditingCellView {
            prototypeCell.configureWithToDoItemCellView(cellView)
        } else {
            prototypeCell.configureWithToDoItem(items[row])
        }

        return prototypeCell.fittingHeightForConstrainedWidth(tableView.bounds.width)
    }

    func tableView(tableView: NSTableView, didAddRowView rowView: NSTableRowView, forRow row: Int) {
        updateColors()
    }

    func tableView(tableView: NSTableView, didRemoveRowView rowView: NSTableRowView, forRow row: Int) {
        updateColors()
    }

    private func updateColors() {
        tableView.enumerateAvailableRowViewsUsingBlock { rowView, row in
            // For some reason tableView.viewAtColumn:row: returns nil while animating, will use view hierarchy instead
            if let cellView = rowView.subviews.first as? ToDoItemCellView {
                NSView.animateWithDuration(0.5, animations: {
                    cellView.backgroundColor = self.colorForRow(row)
                })
            }
        }
    }

    private func colorForRow(row: Int) -> NSColor {
        let fraction = Double(row) / Double(max(13, tableView.numberOfRows))
        return NSColor.taskColors().gradientColorAtFraction(fraction)
    }

}

// MARK: ToDoItemCellViewDelegate

extension ToDoListViewController: ToDoItemCellViewDelegate {

    func cellView(view: ToDoItemCellView, didComplete complete: Bool) {
        guard let (item, index) = findItemForCellView(view) else {
            return
        }

        let destinationIndex: Int

        if complete {
            // move cell to bottom
            destinationIndex = items.count - 1
        } else {
            // move cell just above the first completed item
            let completedCount = items.filter("completed = true").count
            destinationIndex = items.count - completedCount
        }

        delay(0.2) {
            self.skipNextNotification()

            try! item.realm?.write {
                item.completed = complete

                if (index != destinationIndex) {
                    self.items.removeAtIndex(index)
                    self.items.insert(item, atIndex: destinationIndex)
                }
            }

            self.tableView.moveRowAtIndex(index, toIndex: destinationIndex)
            self.updateColors()
        }
    }

    func cellViewDidDelete(view: ToDoItemCellView) {
        guard let (item, index) = findItemForCellView(view) else {
            return
        }

        skipNextNotification()

        try! item.realm?.write {
            items.realm?.delete(item)
        }

        tableView.removeRowsAtIndexes(NSIndexSet(index: index), withAnimation: .SlideLeft)
    }

    func cellViewDidBeginEditing(cellView: ToDoItemCellView) {
        let editingOffset = cellView.convertRect(cellView.bounds, toView: tableView).minY

        topConstraint?.constant = -editingOffset

        NSView.animateWithDuration(0.3, animations: {
            self.view.layoutSubtreeIfNeeded()

            self.tableView.enumerateAvailableRowViewsUsingBlock { _, row in
                if let view = self.tableView.viewAtColumn(0, row: row, makeIfNecessary: false) as? ToDoItemCellView where view != cellView {
                    view.alphaValue = 0.3
                    view.editable = false
                }
            }
        })

        currentlyEditingCellView = cellView
    }

    func cellViewDidChangeText(view: ToDoItemCellView) {
        if view == currentlyEditingCellView {
            updateTableViewHeightOfRows(NSIndexSet(index: tableView.rowForView(view)))
        }
    }

    func cellViewDidEndEditing(view: ToDoItemCellView) {
        guard let (item, index) = findItemForCellView(view) else {
            return
        }

        skipNextNotification()

        try! item.realm?.write {
            if !view.text.isEmpty {
                item.text = view.text
            } else {
                item.realm!.delete(item)

                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.removeRowsAtIndexes(NSIndexSet(index: index), withAnimation: .SlideUp)
                }
            }
        }

        topConstraint?.constant = 0

        NSView.animateWithDuration(0.3, animations: {
            self.view.layoutSubtreeIfNeeded()

            self.tableView.enumerateAvailableRowViewsUsingBlock { _, row in
                if let view = self.tableView.viewAtColumn(0, row: row, makeIfNecessary: false) as? ToDoItemCellView {
                    view.alphaValue = 1
                    view.editable = true
                }
            }
        })

        currentlyEditingCellView = nil
    }

    private func findItemForCellView(view: NSView) -> (item: ToDoItem, index: Int)? {
        let index = tableView.rowForView(view)

        if index < 0 {
            return nil
        }

        return (items[index], index)
    }

}

// MARK: Private Extensions

private extension CollectionType where Generator.Element == Int {

    func toIndexSet() -> NSIndexSet {
        return reduce(NSMutableIndexSet()) { $0.addIndex($1); return $0 }
    }

}

// MARK: Private Functions

private func delay(time: Double, block: () -> ()) {
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue(), block)
}

// MARK: Private Classes

private final class PrototypeToDoItemCellView: ToDoItemCellView {

    private var widthConstraint: NSLayoutConstraint?

    func configureWithToDoItemCellView(cellView: ToDoItemCellView) {
        text = cellView.text
    }

    func fittingHeightForConstrainedWidth(width: CGFloat) -> CGFloat {
        if let constraint = widthConstraint where constraint.constant != width {
            removeConstraint(constraint)
            widthConstraint = nil
        }

        if widthConstraint == nil {
            widthConstraint = NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: width)
            addConstraint(widthConstraint!)
        }

        layoutSubtreeIfNeeded()

        return fittingSize.height
    }

}

private final class SnapshotView: NSView {

    init(sourceView: NSView) {
        super.init(frame: sourceView.frame)

        wantsLayer = true
        shadow = NSShadow() // Workaround to activate layer-backed shadow

        layer?.contents = NSImage(data: sourceView.dataWithPDFInsideRect(sourceView.bounds))!
        layer?.shadowColor = NSColor.blackColor().CGColor
        layer?.shadowOpacity = 1
        layer?.shadowRadius = 5
        layer?.shadowOffset = CGSize(width: -5, height: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
