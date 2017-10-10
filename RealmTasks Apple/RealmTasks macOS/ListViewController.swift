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

import Cartography
import Cocoa
import RealmSwift

fileprivate let taskCellIdentifier = "TaskCell"
fileprivate let listCellIdentifier = "ListCell"
fileprivate let prototypeCellIdentifier = "PrototypeCell"

// FIXME: This type should be split up.
// swiftlint:disable:next type_body_length
final class ListViewController<ListType: ListPresentable>: NSViewController, NSTableViewDelegate, NSTableViewDataSource,
    ItemCellViewDelegate, NSGestureRecognizerDelegate where ListType: Object {

    typealias ItemType = ListType.Item

    let list: ListType

    fileprivate let tableView = NSTableView()

    fileprivate var notificationToken: NotificationToken?

    fileprivate let prototypeCell = PrototypeCellView(identifier: prototypeCellIdentifier)

    fileprivate var currentlyEditingCellView: ItemCellView?

    fileprivate var currentlyMovingRowView: NSTableRowView?
    fileprivate var currentlyMovingRowSnapshotView: SnapshotView?

    private var autoscrollTimer: Timer?

    init(list: ListType) {
        self.list = list

        super.init(nibName: nil, bundle: nil)!
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationToken?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true

        tableView.addTableColumn(NSTableColumn())
        tableView.backgroundColor = .clear
        tableView.headerView = nil
        tableView.selectionHighlightStyle = .none
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

        let notificationCenter = NotificationCenter.default

        // Handle window resizing to update table view rows height
        notificationCenter.addObserver(self, selector: #selector(windowDidResize), name: NSNotification.Name.NSWindowDidResize, object: view.window)
        notificationCenter.addObserver(self, selector: #selector(windowDidResize), name: NSNotification.Name.NSWindowDidEnterFullScreen, object: view.window)
        notificationCenter.addObserver(self, selector: #selector(windowDidResize), name: NSNotification.Name.NSWindowDidExitFullScreen, object: view.window)

        setupNotifications()
        setupGestureRecognizers()

        tableView.delegate = self
        tableView.dataSource = self
    }

    private func setupNotifications() {
        notificationToken = list.items.observe { [unowned self] changes in
            switch changes {
                case .initial:
                    self.tableView.reloadData()
                case .update(_, let deletions, let insertions, let modifications):
                    self.tableView.beginUpdates()
                    self.tableView.removeRows(at: deletions.toIndexSet() as IndexSet, withAnimation: .effectGap)
                    self.tableView.insertRows(at: insertions.toIndexSet() as IndexSet, withAnimation: .effectGap)
                    self.tableView.reloadData(forRowIndexes: modifications.toIndexSet() as IndexSet, columnIndexes: IndexSet(integer: 0))
                    self.tableView.endUpdates()
                case .error(let error):
                    fatalError(String(describing: error))
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

    private func updateTableViewHeightOfRows(indexes: IndexSet? = nil) {
        // noteHeightOfRows animates by default, disable this
        NSView.animate(duration: 0) {
            tableView.noteHeightOfRows(withIndexesChanged: indexes ?? IndexSet(integersIn: Range(0...tableView.numberOfRows)))
        }
    }

    // MARK: UI Writes

    private func beginUIWrite() {
        list.realm?.beginWrite()
    }

    private func commitUIWrite() {
        try! list.realm?.commitWrite(withoutNotifying: [notificationToken!])
    }

    func uiWrite(block: () -> Void) {
        beginUIWrite()
        block()
        commitUIWrite()
    }

    // MARK: Actions

    @IBAction func newItem(_ sender: AnyObject?) {
        endEditingCells()

        uiWrite {
            list.items.insert(ItemType(), at: 0)
        }

        NSView.animate(animations: {
            NSAnimationContext.current().allowsImplicitAnimation = false // prevents NSTableView autolayout issues
            tableView.insertRows(at: NSIndexSet(index: 0) as IndexSet, withAnimation: .effectGap)
        }) {
            if let newItemCellView = self.tableView.view(atColumn: 0, row: 0, makeIfNecessary: false) as? ItemCellView {
                self.beginEditingCell(newItemCellView)
                self.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            }
        }
    }

    override func validateToolbarItem(_ toolbarItem: NSToolbarItem) -> Bool {
        return validateSelector(toolbarItem.action!)
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return validateSelector(menuItem.action!)
    }

    private func validateSelector(_ selector: Selector) -> Bool {
        switch selector {
        case #selector(newItem):
            return !editing || currentlyEditingCellView?.text.isEmpty == false
        default:
            return true
        }
    }

    // MARK: Reordering

    var reordering: Bool {
        return currentlyMovingRowView != nil
    }

    private func beginReorderingRow(atIndex row: Int, screenPoint point: NSPoint) {
        currentlyMovingRowView = tableView.rowView(atRow: row, makeIfNecessary: false)

        if currentlyMovingRowView == nil {
            return
        }

        tableView.enumerateAvailableRowViews { _, row in
            if let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ItemCellView {
                view.isUserInteractionEnabled = false
            }
        }

        currentlyMovingRowSnapshotView = SnapshotView(source: currentlyMovingRowView!)
        currentlyMovingRowView!.alphaValue = 0

        currentlyMovingRowSnapshotView?.frame.origin.y = view.convert(point, from: nil).y - currentlyMovingRowSnapshotView!.frame.height / 2
        view.addSubview(currentlyMovingRowSnapshotView!)

        NSView.animate {
            let frame = currentlyMovingRowSnapshotView!.frame
            currentlyMovingRowSnapshotView!.frame = frame.insetBy(dx: -frame.width * 0.02, dy: -frame.height * 0.02)
        }

        beginUIWrite()
    }

    private func handleReordering(forScreenPoint point: NSPoint) {
        guard reordering else {
            return
        }

        if let snapshotView = currentlyMovingRowSnapshotView {
            snapshotView.frame.origin.y = snapshotView.superview!.convert(point, from: nil).y - snapshotView.frame.height / 2
        }

        let sourceRow = tableView.row(for: currentlyMovingRowView!)
        let destinationRow: Int

        let pointInTableView = tableView.convert(point, from: nil)

        if pointInTableView.y < tableView.bounds.minY {
            destinationRow = 0
        } else if pointInTableView.y > tableView.bounds.maxY {
            destinationRow = tableView.numberOfRows - 1
        } else {
            destinationRow = tableView.row(at: pointInTableView)
        }

        if canMove(row: sourceRow, toRow: destinationRow) {
            list.items.move(from: sourceRow, to: destinationRow)

            NSView.animate {
                // Disable implicit animations because tableView animates reordering via animator proxy
                NSAnimationContext.current().allowsImplicitAnimation = false
                tableView.moveRow(at: sourceRow, to: destinationRow)
            }
        }
    }

    private func canMove(row sourceRow: Int, toRow destinationRow: Int) -> Bool {
        guard destinationRow >= 0 && destinationRow != sourceRow else {
            return false
        }

        return !list.items[destinationRow].completed
    }

    private func endReordering() {
        guard reordering else {
            return
        }

        NSView.animate(animations: {
            currentlyMovingRowSnapshotView?.frame = view.convert(currentlyMovingRowView!.frame, from: tableView)
        }) {
            self.currentlyMovingRowView?.alphaValue = 1
            self.currentlyMovingRowView = nil

            self.currentlyMovingRowSnapshotView?.removeFromSuperview()
            self.currentlyMovingRowSnapshotView = nil

            self.tableView.enumerateAvailableRowViews { _, row in
                if let view = self.tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ItemCellView {
                    view.isUserInteractionEnabled = true
                }
            }

            self.updateColors()
        }

        commitUIWrite()
    }

    private dynamic func handlePressGestureRecognizer(_ recognizer: NSPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            beginReorderingRow(atIndex: tableView.row(at: recognizer.location(in: tableView)), screenPoint: recognizer.location(in: nil))
        case .ended, .cancelled:
            endReordering()
        default:
            break
        }
    }

    private dynamic func handlePanGestureRecognizer(_ recognizer: NSPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startAutoscrolling()
        case .changed:
            handleReordering(forScreenPoint: recognizer.location(in: nil))
        case .ended:
            stopAutoscrolling()
        default:
            break
        }
    }

    private func startAutoscrolling() {
        guard autoscrollTimer == nil else {
            return
        }

        autoscrollTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(handleAutoscrolling), userInfo: nil, repeats: true)
    }

    private dynamic func handleAutoscrolling() {
        if let event = NSApp.currentEvent {
            if tableView.autoscroll(with: event) {
                handleReordering(forScreenPoint: event.locationInWindow)
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

    private func beginEditingCell(_ cellView: ItemCellView) {
        NSView.animate(animations: {
            tableView.scrollRowToVisible(tableView.row(for: cellView))

            tableView.enumerateAvailableRowViews { _, row in
                if let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ItemCellView, view != cellView {
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

        beginUIWrite()
    }

    private func endEditingCells() {
        guard
            let cellView = currentlyEditingCellView,
            let (_, index) = findItem(for: cellView)
        else {
            return
        }

        var item = list.items[index]

        if cellView.text.isEmpty {
            item.realm!.delete(item)
            tableView.removeRows(at: IndexSet(integer: index) as IndexSet, withAnimation: .slideUp)
        } else if cellView.text != item.text {
            item.text = cellView.text
        }

        currentlyEditingCellView = nil

        view.window?.makeFirstResponder(self)
        view.window?.update()

        commitUIWrite()

        NSView.animate(animations: {
            tableView.enumerateAvailableRowViews { _, row in
                if let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ItemCellView {
                    view.alphaValue = 1
                }
            }
        }) {
            self.tableView.enumerateAvailableRowViews { _, row in
                if let view = self.tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? ItemCellView {
                    view.isUserInteractionEnabled = true
                }
            }
        }
    }

    // MARK: NSGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: NSGestureRecognizer) -> Bool {
        return gestureRecognizer is NSPanGestureRecognizer
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: NSGestureRecognizer) -> Bool {
        guard !editing else {
            return false
        }

        switch gestureRecognizer {
        case is NSPressGestureRecognizer:
            let targetRow = tableView.row(at: gestureRecognizer.location(in: tableView))

            guard targetRow >= 0 else {
                return false
            }

            return !list.items[targetRow].completed
        case is NSPanGestureRecognizer:
            return reordering
        default:
            return true
        }
    }

    // MARK: NSTableViewDataSource

    internal func numberOfRows(in tableView: NSTableView) -> Int {
        return list.items.count
    }

    // MARK: NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
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

        if let view = tableView.make(withIdentifier: cellViewIdentifier, owner: self) as? ItemCellView {
            cellView = view
        } else {
            cellView = cellViewType.init(identifier: listCellIdentifier)
        }

        cellView.configure(item: item)
        cellView.backgroundColor = color(forRow: row)
        cellView.delegate = self

        return cellView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if let cellView = currentlyEditingCellView {
            prototypeCell.configure(cellView: cellView)
        } else {
            prototypeCell.configure(item: list.items[row])
        }

        return prototypeCell.fittingHeight(forConstrainedWidth: tableView.bounds.width)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let index = tableView.selectedRow

        guard 0 <= index && index < list.items.count else {
            endEditingCells()
            return
        }

        guard !list.items[index].completed else {
            endEditingCells()
            return
        }

        guard let cellView = tableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? ItemCellView, cellView != currentlyEditingCellView else {
            return
        }

        guard currentlyEditingCellView == nil else {
            endEditingCells()
            return
        }

        if let listCellView = cellView as? ListCellView, !listCellView.acceptsEditing, let list = list.items[index] as? TaskList {
            (parent as? ContainerViewController)?.presentViewController(for: list)
        } else if cellView.isUserInteractionEnabled {
            beginEditingCell(cellView)
        }
    }

    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        updateColors()
    }

    func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int) {
        updateColors()
    }

    private func updateColors() {
        tableView.enumerateAvailableRowViews { rowView, row in
            // For some reason tableView.viewAtColumn:row: returns nil while animating, will use view hierarchy instead
            if let cellView = rowView.subviews.first as? ItemCellView {
                NSView.animate {
                    cellView.backgroundColor = color(forRow: row)
                }
            }
        }
    }

    private func color(forRow row: Int) -> NSColor {
        let colors = ItemType.self is Task.Type ? NSColor.taskColors() : NSColor.listColors()
        let fraction = Double(row) / Double(max(13, list.items.count))

        return colors.gradientColor(atFraction: fraction)
    }

    // MARK: ItemCellViewDelegate

    func cellView(_ view: ItemCellView, didComplete complete: Bool) {
        guard let itemAndIndex = findItem(for: view) else {
            return
        }

        var item = itemAndIndex.0
        let index = itemAndIndex.1
        let destinationIndex: Int

        if complete {
            // move cell to bottom
            destinationIndex = list.items.count - 1
        } else {
            // move cell just above the first completed item
            let completedCount = list.items.filter("completed = true").count
            destinationIndex = list.items.count - completedCount
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.uiWrite {
                item.completed = complete

                if index != destinationIndex {
                    self.list.items.remove(at: index)
                    self.list.items.insert(item, at: destinationIndex)
                }
            }

            NSView.animate(duration: 0.3, animations: {
                NSAnimationContext.current().allowsImplicitAnimation = false
                self.tableView.moveRow(at: index, to: destinationIndex)
            }) {
                self.updateColors()
            }
        }
    }

    func cellViewDidDelete(_ view: ItemCellView) {
        guard let (item, index) = findItem(for: view) else {
            return
        }

        uiWrite {
            list.realm?.delete(item)
        }

        NSView.animate {
            NSAnimationContext.current().allowsImplicitAnimation = false
            tableView.removeRows(at: IndexSet(integer: index), withAnimation: .slideLeft)
        }
    }

    func cellViewDidChangeText(_ view: ItemCellView) {
        if view == currentlyEditingCellView {
            updateTableViewHeightOfRows(indexes: IndexSet(integer: tableView.row(for: view)))
            view.window?.update()
        }
    }

    func cellViewDidEndEditing(_ view: ItemCellView) {
        endEditingCells()

        // In case if Return key was pressed we need to reset table view selection
        tableView.deselectAll(nil)
    }

    private func findItem(for view: ItemCellView) -> (item: ItemType, index: Int)? {
        let index = tableView.row(for: view)

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

    func fittingHeight(forConstrainedWidth width: CGFloat) -> CGFloat {
        if let widthConstraint = widthConstraint {
            widthConstraint.constant = width
        } else {
            widthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil,
                                                 attribute: .notAnAttribute, multiplier: 1, constant: width)
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

    init(source: NSView) {
        super.init(frame: source.frame)

        let imageRepresentation = source.bitmapImageRepForCachingDisplay(in: source.bounds)!
        source.cacheDisplay(in: source.bounds, to: imageRepresentation)

        let snapshotImage = NSImage(size: source.bounds.size)
        snapshotImage.addRepresentation(imageRepresentation)

        wantsLayer = true
        shadow = NSShadow() // Workaround to activate layer-backed shadow

        layer?.contents = snapshotImage
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 1
        layer?.shadowRadius = 5
        layer?.shadowOffset = CGSize(width: -5, height: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: Private Extensions

private extension Collection where Iterator.Element == Int {

    func toIndexSet() -> NSIndexSet {
        return reduce(NSMutableIndexSet()) { $0.add($1); return $0 }
    }

}
