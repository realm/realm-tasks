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

import Cartography
import RealmSwift
import UIKit

// MARK: Private Extensions

extension UIView {
    private var snapshot: UIView {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Create an image view
        let snapshot = UIImageView(image: image)
        snapshot.layer.masksToBounds = false
        snapshot.layer.cornerRadius = 0
        snapshot.layer.shadowOffset = CGSizeMake(-5, 0)
        snapshot.layer.shadowRadius = 5
        snapshot.layer.shadowOpacity = 0
        return snapshot
    }
}

// MARK: Private Functions

private func delay(time: Double, block: () -> ()) {
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue(), block)
}

private func degreesToRadians(value: Double) -> Double {
    return value * M_PI / 180
}

// MARK: View Controller

final class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate, UIGestureRecognizerDelegate {

    // MARK: Properties

    // Stored Properties
    private var items = try! Realm().objects(ToDoList).first!.items
    private let tableView = UITableView()
    private var notificationToken: NotificationToken?
    private var disableNotificationsState = false

    // Computed Properties
    private var visibleTableViewCells: [TableViewCell] { return tableView.visibleCells as! [TableViewCell] }

    // Scrolling
    private var distancePulledDown: CGFloat {
        return -tableView.contentOffset.y - tableView.contentInset.top
    }
    private var distancePulledUp: CGFloat {
        return tableView.contentOffset.y + tableView.bounds.size.height - max(tableView.bounds.size.height, tableView.contentSize.height)
    }

    // Moving
    private var snapshot: UIView! = nil
    private var startIndexPath: NSIndexPath? = nil
    private var sourceIndexPath: NSIndexPath? = nil

    // Editing
    private var currentlyEditing: Bool { return currentlyEditingCell != nil }
    private var currentlyEditingCell: TableViewCell? {
        didSet {
            tableView.scrollEnabled = !currentlyEditing
        }
    }
    private var currentlyEditingIndexPath: NSIndexPath? = nil
    private var topConstraint: NSLayoutConstraint?
    private var previousContentOffset = CGPoint.zero

    // Placeholder cell to use before being adding to the table view
    private let placeHolderCell = TableViewCell(style: .Default, reuseIdentifier: "cell")
    private let textEditingCell = TableViewCell(style: .Default, reuseIdentifier: "cell")

    // Onboard view
    private let onboardView = OnboardView()

    // Constants
    let editingCellAlpha: CGFloat = 0.3

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestureRecognizers()
    }

    // MARK: UI

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    private func setupUI() {
        setupTableView()
        setupPlaceholderCell()
        setupTitleBar()
        setupNotifications()
        toggleOnboardView()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        constrain(tableView) { tableView in
            topConstraint = (tableView.top == tableView.superview!.top)
            tableView.right == tableView.superview!.right
            tableView.bottom == tableView.superview!.bottom
            tableView.left == tableView.superview!.left
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(TableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .None
        tableView.backgroundColor = .blackColor()
        tableView.rowHeight = 54
        tableView.contentInset = UIEdgeInsets(top: 45, left: 0, bottom: 54, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
        tableView.showsVerticalScrollIndicator = false
    }

    private func setupPlaceholderCell() {
        placeHolderCell.alpha = 0
        placeHolderCell.backgroundView!.backgroundColor = UIColor().realmColors[0]
        placeHolderCell.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        tableView.addSubview(placeHolderCell)
        constrain(placeHolderCell) { placeHolderCell in
            placeHolderCell.bottom == placeHolderCell.superview!.topMargin - 7 + 26
            placeHolderCell.left == placeHolderCell.superview!.superview!.left
            placeHolderCell.right == placeHolderCell.superview!.superview!.right
            placeHolderCell.height == tableView.rowHeight
        }
    }

    private func setupTitleBar() {
        let titleBar = UIToolbar()
        titleBar.barStyle = .BlackTranslucent
        view.addSubview(titleBar)
        constrain(titleBar) { titleBar in
            titleBar.left == titleBar.superview!.left
            titleBar.top == titleBar.superview!.top
            titleBar.right == titleBar.superview!.right
            titleBar.height == 45
        }

        let titleLabel = UILabel()
        titleLabel.font = .boldSystemFontOfSize(13)
        titleLabel.textAlignment = .Center
        titleLabel.text = "My Items"
        titleLabel.textColor = .whiteColor()
        titleBar.addSubview(titleLabel)
        constrain(titleLabel) { titleLabel in
            titleLabel.left == titleLabel.superview!.left
            titleLabel.right == titleLabel.superview!.right
            titleLabel.bottom == titleLabel.superview!.bottom - 5
        }
    }

    private func setupNotifications() {
        if notificationToken != nil {
            return
        }

        notificationToken = items.addNotificationBlock { changes in
            if self.disableNotificationsState {
                return
            }

            // FIXME: Hack to work around sync possibly pulling in a new list.
            // Ideally we'd use ToDoList with primary keys, but those aren't currently supported by sync.
            let realm = self.items.realm!
            let lists = realm.objects(ToDoList)
            let hasMultipleLists = lists.count > 1
            if hasMultipleLists { self.items = lists.first!.items }
            defer {
                if hasMultipleLists {
                    // Append all other items while deleting their lists, in case they were created locally before sync
                    try! realm.write {
                        while lists.count > 1 {
                            self.items.appendContentsOf(lists.last!.items)
                            realm.delete(lists.last!)
                        }
                    }
                }
            }

            switch changes {
            case .Initial:
                // Results are now populated and can be accessed without blocking the UI
                self.tableView.reloadData()
            case .Update(_, let deletions, let insertions, let modifications):
                let updateTableView = {
                    // Query results have changed, so apply them to the UITableView
                    self.tableView.beginUpdates()
                    self.tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
                    self.tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
                    self.tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) },withRowAnimation: .Automatic)
                    self.tableView.endUpdates()
                }

                if let currentlyEditingIndexPath = self.currentlyEditingIndexPath {
                    UIView.performWithoutAnimation {
                        // FIXME: Updating table view forces resigning first responder
                        // If editing, unintended input state is committed and sync.
                        self.currentlyEditingCell?.temporarilyIgnoreSaveChanges = true
                        updateTableView()
                        let currentlyEditingCell = self.tableView.cellForRowAtIndexPath(currentlyEditingIndexPath) as! TableViewCell
                        currentlyEditingCell.temporarilyIgnoreSaveChanges = false
                        currentlyEditingCell.textView.becomeFirstResponder()
                    }
                } else {
                    updateTableView()
                }

                self.updateColors()
                self.toggleOnboardView(animated: true)
            case .Error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }

    func cellHeightForText(text: NSString) -> CGFloat {
        var size = view.bounds.size
        size.width -= 25

        let height = text.boundingRectWithSize(size,
                                               options: [.UsesLineFragmentOrigin],
                                               attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18)],
                                               context: nil).height
        return ceil(height) + 33
    }

    private func toggleOnboardView(animated animated: Bool = false) {
        if onboardView.superview == nil {
            tableView.addSubview(onboardView)
            onboardView.center = tableView.center
        }

        let numberOfRows = tableView.numberOfRowsInSection(0)
        let hidden = (numberOfRows > 0 || textEditingCell.superview != nil)

        if animated == false {
            onboardView.alpha = hidden ? 0 : 1
            return
        }

        onboardView.alpha = hidden ? 1 : 0
        UIView.animateWithDuration(0.3) {
            self.onboardView.alpha = hidden ? 0 : 1
        }
    }

    // MARK: Gesture Recognizers

    private func setupGestureRecognizers() {
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(_:))))

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(_:)))
        longPressGestureRecognizer.delegate = self
        tableView.addGestureRecognizer(longPressGestureRecognizer)
    }

    func tapGestureRecognized(recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .Ended else {
            return
        }
        if currentlyEditing {
            view.endEditing(true)
        } else if let indexPath = tableView.indexPathForRowAtPoint(recognizer.locationInView(tableView)),
            cell = tableView.cellForRowAtIndexPath(indexPath) as? TableViewCell {
            cell.textView.userInteractionEnabled = !cell.textView.userInteractionEnabled
            cell.textView.becomeFirstResponder()
        }
    }

    func longPressGestureRecognized(recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(location) ?? NSIndexPath(forRow: items.count - 1, inSection: 0)
        switch recognizer.state {
        case .Possible: break
        case .Began:
            guard let cell = tableView.cellForRowAtIndexPath(indexPath) else { break }
            startIndexPath = indexPath
            sourceIndexPath = indexPath

            // Add the snapshot as subview, aligned with the cell
            var center = cell.center
            snapshot = cell.snapshot
            snapshot.center = center
            cell.hidden = true
            tableView.addSubview(snapshot)

            // Animate
            UIView.animateWithDuration(0.3) { [unowned self] in
                center.y = location.y
                self.snapshot.center = center
                self.snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05)
                self.snapshot.layer.shadowColor = UIColor.blackColor().CGColor
                self.snapshot.layer.shadowOpacity = 1
            }
            break
        case .Changed:
            var center = snapshot.center
            center.y = location.y
            snapshot.center = center

            guard let sourceIndexPath = sourceIndexPath
                where indexPath != sourceIndexPath else { break }

            self.sourceIndexPath = indexPath

            // move rows
            tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath: indexPath)

            break
        case .Ended, .Cancelled, .Failed:
            guard let cell = tableView.cellForRowAtIndexPath(indexPath),
                startIndexPath = startIndexPath,
                sourceIndexPath = sourceIndexPath else { break }

            // update data source & move rows
            try! items.realm?.write {
                let item = items[startIndexPath.row]
                items.removeAtIndex(startIndexPath.row)
                items.insert(item, atIndex: indexPath.row)
            }
            temporarilyDisableNotifications(reloadTable: false)

            self.startIndexPath = nil
            self.sourceIndexPath = nil

            tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath: indexPath)

            UIView.animateWithDuration(0.3, animations: { [unowned self] in
                self.snapshot.center = cell.center
                self.snapshot.transform = CGAffineTransformIdentity
                self.snapshot.layer.shadowOpacity = 0
            }, completion: { [unowned self] _ in
                cell.hidden = false
                self.snapshot.removeFromSuperview()
                self.snapshot = nil

                self.updateColors {
                    UIView.performWithoutAnimation {
                        self.tableView.reloadData()
                    }
                }
            })
            break
        }
    }

    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.locationInView(tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) as? TableViewCell {
            return !cell.item.completed
        }
        return true
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! TableViewCell
        cell.item = items[indexPath.row]
        cell.delegate = self

        if let editingIndexPath = currentlyEditingIndexPath {
            if editingIndexPath.row != indexPath.row { cell.alpha = editingCellAlpha }
        }

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if currentlyEditingIndexPath?.row == indexPath.row {
            return cellHeightForText(currentlyEditingCell!.textView.text)
        }

        var item = items[indexPath.row]

        // If we are dragging an item around, swap those 
        // two items for their appropriate height values
        if let startIndexPath = startIndexPath, sourceIndexPath = sourceIndexPath {
            if indexPath.row == sourceIndexPath.row {
                item = items[startIndexPath.row]
            } else if indexPath.row == startIndexPath.row {
                item = items[sourceIndexPath.row]
            }
        }

        return cellHeightForText(item.text)
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.contentView.backgroundColor = realmColor(forIndexPath: indexPath)
        cell.alpha = currentlyEditing ? editingCellAlpha : 1
    }

    // MARK: UIScrollViewDelegate methods

    func scrollViewDidScroll(scrollView: UIScrollView)  {
        guard distancePulledDown > 0 else { return }

        if distancePulledDown <= tableView.rowHeight {
            placeHolderCell.textView.text = "Pull to Create Item"

            let cellHeight = tableView.rowHeight
            let angle = CGFloat(degreesToRadians(90)) - tan(distancePulledDown / cellHeight)

            var transform = CATransform3DIdentity
            transform.m34 = 1 / -(1000 * 0.2)
            transform = CATransform3DRotate(transform, angle, 1, 0, 0)

            placeHolderCell.layer.transform = transform

            if tableView.numberOfRowsInSection(0) == 0 {
                onboardView.alpha = max(0, 1 - (distancePulledDown / cellHeight))
            } else {
                onboardView.alpha = 0
            }
        } else {
            placeHolderCell.layer.transform = CATransform3DIdentity
            placeHolderCell.textView.text = "Release to Create Item"
        }

        if scrollView.dragging {
            placeHolderCell.alpha = min(1, distancePulledDown / tableView.rowHeight)
        }
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard distancePulledUp < 160 else {
            let itemsToDelete = items.filter("completed = true")
            guard !itemsToDelete.isEmpty else { return }

            try! items.realm?.write {
                items.realm?.delete(itemsToDelete)
            }
            temporarilyDisableNotifications()

            vibrate()
            return
        }

        guard distancePulledDown > tableView.rowHeight else { return }

        // exceeds threshold
        textEditingCell.frame = placeHolderCell.bounds
        textEditingCell.frame.origin.y = tableView.contentInset.top + (distancePulledDown - tableView.rowHeight)
        textEditingCell.backgroundView!.backgroundColor = placeHolderCell.backgroundView!.backgroundColor
        view.addSubview(textEditingCell)

        textEditingCell.item = ToDoItem(text: "")
        textEditingCell.delegate = self

        textEditingCell.textView.userInteractionEnabled = true
        textEditingCell.textView.becomeFirstResponder()

        toggleOnboardView()
    }

    // MARK: TableViewCellDelegate

    func itemDeleted(item: ToDoItem) {
        guard let index = items.indexOf(item) else {
            return
        }

        try! items.realm?.write {
            items.realm?.delete(item)
        }

        tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Left)
        temporarilyDisableNotifications(reloadTable: false)

        toggleOnboardView()

        delay(0.2) {
            [weak self] in

            self?.updateColors {
                self?.tableView.reloadData()
            }
        }
    }

    func itemCompleted(item: ToDoItem) {
        guard let index = items.indexOf(item) else {
            return
        }
        let sourceIndexPath = NSIndexPath(forRow: index, inSection: 0)
        let destinationIndexPath: NSIndexPath
        if item.completed {
            // move cell to bottom
            destinationIndexPath = NSIndexPath(forRow: items.count - 1, inSection: 0)
        } else {
            // move cell just above the first completed item
            let completedCount = items.filter("completed = true").count
            destinationIndexPath = NSIndexPath(forRow: items.count - completedCount - 1, inSection: 0)
        }
        delay(0.2) { [weak self] in
            try! self?.items.realm?.write {
                self!.items.removeAtIndex(sourceIndexPath.row)
                self!.items.insert(item, atIndex: destinationIndexPath.row)
            }

            self?.tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath: destinationIndexPath)
            self?.temporarilyDisableNotifications()
        }
        delay(0.6) { [weak self] in self?.updateColors() }
    }

    func cellDidBeginEditing(editingCell: TableViewCell) {
        currentlyEditingCell = editingCell
        currentlyEditingIndexPath = tableView.indexPathForCell(editingCell)

        let editingOffset = editingCell.convertRect(editingCell.bounds, toView: tableView).origin.y
        if editingOffset >= tableView.contentSize.height / 2 {
            topConstraint?.constant = -editingOffset
        } else {
            topConstraint?.constant = -(editingOffset + distancePulledDown)
        }
        previousContentOffset = tableView.contentOffset

        placeHolderCell.alpha = 0
        tableView.bounces = false

        UIView.animateWithDuration(0.3, animations: { [unowned self] in
            self.view.layoutSubviews()
            self.textEditingCell.frame.origin.y = 45
            for cell in self.visibleTableViewCells where cell !== editingCell {
                cell.alpha = self.editingCellAlpha
            }
        }, completion: { [unowned self] finished in
            self.tableView.bounces = true
        })
    }

    func cellDidEndEditing(editingCell: TableViewCell) {
        currentlyEditingCell = nil
        currentlyEditingIndexPath = nil

        topConstraint?.constant = 0
        UIView.animateWithDuration(0.3) { [unowned self] in
            self.tableView.contentOffset = self.previousContentOffset
            for cell in self.visibleTableViewCells where cell !== editingCell {
                cell.alpha = 1
            }
        }

        if let item = editingCell.item where editingCell == textEditingCell && !item.text.isEmpty {
            try! items.realm?.write {
                items.insert(item, atIndex: 0)
            }

            UIView.performWithoutAnimation {
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .None)
            }
            temporarilyDisableNotifications()

            updateColors()
        } else {
            UIView.animateWithDuration(0.3) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.view.layoutSubviews()
            }
        }

        if textEditingCell.superview != nil {
            textEditingCell.removeFromSuperview()
        }

        toggleOnboardView()
    }

    func cellDidChangeText(editingCell: TableViewCell) {
        // If the height of the text view has extended to the next line,
        // reload the height of the cell
        let height = cellHeightForText(editingCell.textView.text)
        if Int(height) != Int(editingCell.frame.size.height) {
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }

            for cell in visibleTableViewCells where cell !== editingCell {
                cell.alpha = editingCellAlpha
            }

            if editingCell == textEditingCell {
                var frame = textEditingCell.frame
                frame.size.height = cellHeightForText(textEditingCell.textView.text)
                textEditingCell.frame = frame
                textEditingCell.textView.sizeToFit()
                textEditingCell.layoutSubviews()
                textEditingCell.setNeedsDisplay()

                let editingOffset = editingCell.convertRect(textEditingCell.bounds, toView: tableView).origin.y
                topConstraint?.constant = -editingOffset
                view.layoutSubviews()
            }
        }
    }

    // MARK: Actions

    private func realmColor(forIndexPath indexPath: NSIndexPath) -> UIColor {
        return .colorForRealmLogoGradient(Double(indexPath.row) / Double(max(13, tableView.numberOfRowsInSection(0))))
    }

    private func updateColors(completion completion: (() -> Void)? = nil) {
        let visibleIndexPaths = visibleTableViewCells.flatMap(tableView.indexPathForCell)

        UIView.animateWithDuration(0.5, animations: {
            for indexPath in visibleIndexPaths {
                let cell = self.tableView.cellForRowAtIndexPath(indexPath)
                cell?.contentView.backgroundColor = self.realmColor(forIndexPath: indexPath)
            }
        }, completion: { completed in
            completion?()
        })
    }

    // MARK: Sync

    private func temporarilyDisableNotifications(reloadTable reloadTable: Bool = true) {
        disableNotificationsState = true
        delay(0.3) {
            self.disableNotificationsState = false

            if reloadTable {
                self.tableView.reloadData()
            }
        }
    }
}
