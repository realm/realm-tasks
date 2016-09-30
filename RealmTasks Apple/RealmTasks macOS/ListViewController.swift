////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

// FIXME: This file should be split up.
// swiftlint:disable file_length

import Cocoa
import RealmSwift
import Cartography

private let taskCellIdentifier = "TaskCell"
private let listCellIdentifier = "ListCell"
private let prototypeCellIdentifier = "PrototypeCell"

final class ListViewController<ListType: ListPresentable where ListType: Object>: NSViewController, NSTableViewDelegate, NSTableViewDataSource, ItemCellViewDelegate, NSGestureRecognizerDelegate {

    typealias ItemType = ListType.Item

    let list: ListType

    private let tableView = NSTableView()

    private var notificationToken: NotificationToken?

    private let prototypeCell = PrototypeCellView(identifier: prototypeCellIdentifier)

    private var currentlyEditingCellView: ItemCellView?

    private var currentlyMovingRowView: NSTableRowView?
    private var currentlyMovingRowSnapshotView: SnapshotView?
    private var movingStarted = false

    private var autoscrollTimer: NSTimer?

    init(list: ListType) {
        self.list = list

        super.init(nibName: nil, bundle: nil)!
    }

    deinit {
        notificationToken?.stop()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true

        tableView.addTableColumn(NSTableColumn())
        tableView.backgroundColor = .clearColor()
        tableView.headerView = nil
        tableView.selectionHighlightStyle = .None
        tableView.intercellSpacing = .zero

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.drawsBackground = false

        view.addSubview(scrollView)

        constrain(scrollView) { scrollView in
            scrollView.edges == scrollView.superview!.edges
        }
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

        tableView.delegate = self
        tableView.dataSource = self
    }

    private func setupNotifications() {
        notificationToken = list.items.addNotificationBlock { [unowned self] changes in
            if !self.reordering && !self.editing {
                self.tableView.reloadData()
            }
        }
    }

    private func setupGestureRecognizers() {
        let pressGestureRecognizer = NSPressGestureRecognizer(target: self, action: #selector(handlePressGestureRecognizer))
        pressGestureRecognizer.minimumPressDuration = 0.2

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
        NSView.animate(duration: 0) {
            self.tableView.noteHeightOfRowsWithIndexesChanged(indexes ?? NSIndexSet(indexesInRange: NSRange(0...self.tableView.numberOfRows)))
        }
    }

    // MARK: Actions

    @IBAction func newItem(sender: AnyObject?) {
        try! list.realm?.write {
            self.list.items.insert(ItemType(), atIndex: 0)
        }

        NSView.animate(animations: {
            NSAnimationContext.currentContext().allowsImplicitAnimation = false // prevents NSTableView autolayout issues
            self.tableView.insertRowsAtIndexes(NSIndexSet(index: 0), withAnimation: .EffectGap)
        }) {
            if let newItemCellView = self.tableView.viewAtColumn(0, row: 0, makeIfNecessary: false) as? ItemCellView {
                self.beginEditingCell(newItemCellView)
                self.tableView.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
            }
        }
    }

    override func validateToolbarItem(theItem: NSToolbarItem) -> Bool {
        if theItem.action == #selector(newItem) && currentlyEditingCellView != nil {
            return false
        }

        return true
    }

    // MARK: Reordering

    var reordering: Bool {
        return currentlyMovingRowView != nil
    }

    private func beginReorderingRow(row: Int, screenPoint point: NSPoint) {
        currentlyMovingRowView = tableView.rowViewAtRow(row, makeIfNecessary: false)

        if currentlyMovingRowView == nil {
            return
        }

        tableView.enumerateAvailableRowViewsUsingBlock { _, row in
            if let view = self.tableView.viewAtColumn(0, row: row, makeIfNecessary: false) as? ItemCellView {
                view.isUserInteractionEnabled = false
            }
        }

        currentlyMovingRowSnapshotView = SnapshotView(sourceView: currentlyMovingRowView!)
        currentlyMovingRowView!.alphaValue = 0

        currentlyMovingRowSnapshotView?.frame.origin.y = view.convertPoint(point, fromView: nil).y - currentlyMovingRowSnapshotView!.frame.height / 2
        view.addSubview(currentlyMovingRowSnapshotView!)

        NSView.animate() {
            let frame = self.currentlyMovingRowSnapshotView!.frame
            self.currentlyMovingRowSnapshotView!.frame = frame.insetBy(dx: -frame.width * 0.02, dy: -frame.height * 0.02)
        }
    }

    private func handleReorderingForScreenPoint(point: NSPoint) {
        if let snapshotView = currentlyMovingRowSnapshotView {
            snapshotView.frame.origin.y = snapshotView.superview!.convertPoint(point, fromView: nil).y - snapshotView.frame.height / 2
        }

        let sourceRow = tableView.rowForView(currentlyMovingRowView!)
        let destinationRow: Int

        let pointInTableView = tableView.convertPoint(point, fromView: nil)

        if pointInTableView.y < tableView.bounds.minY {
            destinationRow = 0
        } else if pointInTableView.y > tableView.bounds.maxY {
            destinationRow = tableView.numberOfRows - 1
        } else {
            destinationRow = tableView.rowAtPoint(pointInTableView)
        }

        if canMoveRow(sourceRow, toRow: destinationRow) {
            try! list.realm?.write {
                list.items.move(from: sourceRow, to: destinationRow)
            }

            NSView.animate() {
                // Disable implicit animations because tableView animates reordering via animator proxy
                NSAnimationContext.currentContext().allowsImplicitAnimation = false
                self.tableView.moveRowAtIndex(sourceRow, toIndex: destinationRow)
            }
        }
    }

    private func canMoveRow(sourceRow: Int, toRow destinationRow: Int) -> Bool {
        guard destinationRow >= 0 && destinationRow != sourceRow else {
            return false
        }

        return !list.items[destinationRow].completed
    }

    private func endReordering() {
        NSView.animate(animations: {
            self.currentlyMovingRowSnapshotView?.frame = self.view.convertRect(self.currentlyMovingRowView!.frame, fromView: self.tableView)
        }) {
            self.currentlyMovingRowView?.alphaValue = 1
            self.currentlyMovingRowView = nil

            self.currentlyMovingRowSnapshotView?.removeFromSuperview()
            self.currentlyMovingRowSnapshotView = nil

            self.tableView.reloadData()
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
            movingStarted = false
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

    // MARK: Editing

    var editing: Bool {
        return currentlyEditingCellView != nil
    }

    private func beginEditingCell(cellView: ItemCellView) {
        NSView.animate(animations: {
            self.tableView.scrollRowToVisible(self.tableView.rowForView(cellView))

            self.tableView.enumerateAvailableRowViewsUsingBlock { _, row in
                if let view = self.tableView.viewAtColumn(0, row: row, makeIfNecessary: false) as? ItemCellView where view != cellView {
                    view.alphaValue = 0.3
                    view.isUserInteractionEnabled = false
                }
            }
        }) {
            self.view.window?.update()
        }

        cellView.editable = true
        view.window?.makeFirstResponder(cellView.textView)

        currentlyEditingCellView = cellView
    }

    private func endEditingCells() {
        view.window?.makeFirstResponder(self)

        NSView.animate(animations: {
            self.tableView.enumerateAvailableRowViewsUsingBlock { _, row in
                if let view = self.tableView.viewAtColumn(0, row: row, makeIfNecessary: false) {
                    view.alphaValue = 1
                }
            }
        }) {
            self.currentlyEditingCellView = nil
            self.view.window?.update()
            self.tableView.reloadData()
        }
    }

    // MARK: NSGestureRecognizerDelegate

    func gestureRecognizer(gestureRecognizer: NSGestureRecognizer,
                           shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: NSGestureRecognizer) -> Bool {
        return gestureRecognizer is NSPanGestureRecognizer
    }

    func gestureRecognizerShouldBegin(gestureRecognizer: NSGestureRecognizer) -> Bool {
        switch gestureRecognizer {
        case is NSPressGestureRecognizer:
            let targetRow = tableView.rowAtPoint(gestureRecognizer.locationInView(tableView))

            guard targetRow >= 0,
                let cellView = tableView.viewAtColumn(0, row: targetRow, makeIfNecessary: false) as? ItemCellView else {
                return false
            }

            return cellView != currentlyEditingCellView && !cellView.completed
        case is NSPanGestureRecognizer:
            return reordering
        default:
            return true
        }
    }

    // MARK: NSTableViewDataSource

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return list.items.count
    }

    // MARK: NSTableViewDelegate

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = list.items[row]

        let cellViewIdentifier: String
        let cellViewType: ItemCellView.Type
        let cellView: ItemCellView

        switch item {
        case is TaskList:
            cellViewIdentifier = listCellIdentifier
            cellViewType = ListCellView.self
        case is Task:
            cellViewIdentifier = taskCellIdentifier
            cellViewType = TaskCellView.self
        default:
            fatalError("Unknown item type")
        }

        if let view = tableView.makeViewWithIdentifier(cellViewIdentifier, owner: self) as? ItemCellView {
            cellView = view
        } else {
            cellView = cellViewType.init(identifier: listCellIdentifier)
        }

        cellView.configure(item)
        cellView.backgroundColor = colorForRow(row)
        cellView.delegate = self

        return cellView
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if let cellView = currentlyEditingCellView {
            prototypeCell.configure(cellView)
        } else {
            prototypeCell.configure(list.items[row])
        }

        return prototypeCell.fittingHeightForConstrainedWidth(tableView.bounds.width)
    }

    func tableViewSelectionDidChange(notification: NSNotification) {
        let index = tableView.selectedRow

        guard 0 <= index && index < list.items.count else {
            endEditingCells()
            return
        }

        guard !list.items[index].completed else {
            endEditingCells()
            return
        }

        guard let cellView = tableView.viewAtColumn(0, row: index, makeIfNecessary: false) as? ItemCellView where cellView != currentlyEditingCellView else {
            return
        }

        guard currentlyEditingCellView == nil else {
            endEditingCells()
            return
        }

        if let listCellView = cellView as? ListCellView where !listCellView.acceptsEditing, let list = list.items[index] as? TaskList {
            (parentViewController as? ContainerViewController)?.presentViewControllerForList(list)
        } else {
            beginEditingCell(cellView)
        }
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
            if let cellView = rowView.subviews.first as? ItemCellView {
                NSView.animate() {
                    cellView.backgroundColor = self.colorForRow(row)
                }
            }
        }
    }

    private func colorForRow(row: Int) -> NSColor {
        let colors = ItemType.self is Task.Type ? NSColor.taskColors() : NSColor.listColors()
        let fraction = Double(row) / Double(max(13, list.items.count))

        return colors.gradientColorAtFraction(fraction)
    }

    // MARK: ItemCellViewDelegate

    func cellView(view: ItemCellView, didComplete complete: Bool) {
        guard let (tmpItem, index) = findItemForCellView(view) else {
            return
        }

        // FIXME: workaround for tuple mutability
        var item = tmpItem

        let destinationIndex: Int

        if complete {
            // move cell to bottom
            destinationIndex = list.items.count - 1
        } else {
            // move cell just above the first completed item
            let completedCount = list.items.filter("completed = true").count
            destinationIndex = list.items.count - completedCount
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            try! item.realm?.write {
                item.completed = complete

                if index != destinationIndex {
                    self.list.items.removeAtIndex(index)
                    self.list.items.insert(item, atIndex: destinationIndex)
                }
            }

            self.tableView.moveRowAtIndex(index, toIndex: destinationIndex)
            self.updateColors()
        }
    }

    func cellViewDidDelete(view: ItemCellView) {
        guard let (item, index) = findItemForCellView(view) else {
            return
        }

        try! list.realm?.write {
            list.realm?.delete(item)
        }

        tableView.removeRowsAtIndexes(NSIndexSet(index: index), withAnimation: .SlideLeft)
    }

    func cellViewDidChangeText(view: ItemCellView) {
        if view == currentlyEditingCellView {
            updateTableViewHeightOfRows(NSIndexSet(index: tableView.rowForView(view)))
        }
    }

    func cellViewDidEndEditing(view: ItemCellView) {
        guard let (tmpItem, index) = findItemForCellView(view) else {
            return
        }

        if view.text != tmpItem.text || view.text.isEmpty {
            // Workaround for tuple mutability
            var item = tmpItem

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
        }

        // In case if Return key was pressed we need to reset table view selection
        tableView.selectRowIndexes(NSIndexSet(), byExtendingSelection: false)
    }

    private func findItemForCellView(view: NSView) -> (item: ItemType, index: Int)? {
        let index = tableView.rowForView(view)

        if index < 0 {
            return nil
        }

        return (list.items[index], index)
    }

}

// MARK: Private Classes

private final class PrototypeCellView: ItemCellView {

    private var widthConstraint: NSLayoutConstraint?

    func configure(cellView: ItemCellView) {
        text = cellView.text
    }

    func fittingHeightForConstrainedWidth(width: CGFloat) -> CGFloat {
        if let widthConstraint = widthConstraint {
            widthConstraint.constant = width
        } else {
            widthConstraint = NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: nil,
                                                 attribute: .NotAnAttribute, multiplier: 1, constant: width)
            addConstraint(widthConstraint!)
        }

        layoutSubtreeIfNeeded()

        // NSTextField's content size must be recalculated after cell size is changed  
        textView.invalidateIntrinsicContentSize()
        layoutSubtreeIfNeeded()

        return fittingSize.height
    }

}

private final class SnapshotView: NSView {

    init(sourceView: NSView) {
        super.init(frame: sourceView.frame)

        let imageRepresentation = sourceView.bitmapImageRepForCachingDisplayInRect(sourceView.bounds)!
        sourceView.cacheDisplayInRect(sourceView.bounds, toBitmapImageRep: imageRepresentation)

        let snapshotImage = NSImage(size: sourceView.bounds.size)
        snapshotImage.addRepresentation(imageRepresentation)

        wantsLayer = true
        shadow = NSShadow() // Workaround to activate layer-backed shadow

        layer?.contents = snapshotImage
        layer?.shadowColor = NSColor.blackColor().CGColor
        layer?.shadowOpacity = 1
        layer?.shadowRadius = 5
        layer?.shadowOffset = CGSize(width: -5, height: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
