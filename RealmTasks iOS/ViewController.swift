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

extension UIView {
    private func removeAllConstraints() {
        var view: UIView? = self
        while let superview = view?.superview {
            for c in superview.constraints where c.firstItem === self || c.secondItem === self {
                superview.removeConstraint(c)
            }
            view = superview.superview
        }
        translatesAutoresizingMaskIntoConstraints = true
    }
}

private var tableViewBoundsKVOContext = 0
private var titleKVOContext = 0
private var firstSyncWorkaroundToken: dispatch_once_t = 0

private enum NavDirection {
    case Up, Down
}

// MARK: View Controller

final class ViewController<Item: Object, Parent: Object where Item: CellPresentable, Parent: ListPresentable, Parent.Item == Item>: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {

    // MARK: Properties

    // Items
    private var parent: Parent
    private var items: List<Item> { return parent.items }

    // Table View
    private let tableView = UITableView()
    private let tableViewContentView = UIView()

    // Notifications
    private var notificationToken: NotificationToken?
    private var realmNotificationToken: NotificationToken?
    private var skipNotification = false
    private var reloadOnNotification = false

    // Scrolling
    private var distancePulledDown: CGFloat {
        return -tableView.contentOffset.y - tableView.contentInset.top
    }
    private var distancePulledUp: CGFloat {
        return tableView.contentOffset.y + tableView.bounds.size.height - max(tableView.bounds.size.height, tableView.contentSize.height)
    }

    // Moving
    private var snapshot: UIView!
    private var startIndexPath: NSIndexPath?
    private var destinationIndexPath: NSIndexPath?

    // Editing
    private var currentlyEditing: Bool { return currentlyEditingCell != nil }
    private var currentlyEditingCell: TableViewCell<Item>? {
        didSet {
            tableView.scrollEnabled = !currentlyEditing
        }
    }
    private var currentlyEditingIndexPath: NSIndexPath?

    // Auto Layout
    private var topConstraint: NSLayoutConstraint?
    private var nextConstraints: ConstraintGroup?

    // Placeholder cell to use before being adding to the table view
    private let placeHolderCell = TableViewCell<Item>(style: .Default, reuseIdentifier: "cell")

    // Onboard view
    private let onboardView = OnboardView()

    // Constants
    private let editingCellAlpha: CGFloat = 0.3
    private let colors: [UIColor]

    // Top/Bottom View Controllers
    private let createTopViewController: (() -> (UIViewController))?
    private var topViewController: UIViewController?
    private let createBottomViewController: (() -> (UIViewController))?
    private var bottomViewController: UIViewController?

    // MARK: View Lifecycle

    init(parent: Parent, colors: [UIColor]) {
        self.parent = parent
        self.colors = colors
        if Item.self == Task.self {
            createTopViewController = {
                ViewController<TaskList, TaskListList>(
                    parent: try! Realm().objects(TaskListList.self).first!,
                    colors: UIColor.listColors()
                )
            }
            createBottomViewController = nil
        } else {
            createTopViewController = nil
            createBottomViewController = {
                ViewController<Task, TaskList>(
                    parent: try! Realm().objects(TaskList.self).first!,
                    colors: UIColor.taskColors()
                )
            }
        }
        super.init(nibName: nil, bundle: nil)
        if let parent = parent as? CellPresentable {
            (parent as! Object).addObserver(self, forKeyPath: "text", options: .New, context: &titleKVOContext)
            title = parent.text
        }
    }

    deinit {
        notificationToken?.stop()
        realmNotificationToken?.stop()
        tableView.removeObserver(self, forKeyPath: "bounds")
        parent.removeObserver(self, forKeyPath: "text")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        dispatch_once(&firstSyncWorkaroundToken, setupFirstSyncWorkaround)
        setupNotifications()
        setupGestureRecognizers()
    }

    // MARK: UI

    private func setupUI() {
        setupTableView()
        setupPlaceholderCell()
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
        tableView.registerClass(TableViewCell<Item>.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .None
        tableView.backgroundColor = .blackColor()
        tableView.rowHeight = 54
        tableView.contentInset = UIEdgeInsets(top: (title != nil) ? 41 : 20, left: 0, bottom: 54, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
        tableView.showsVerticalScrollIndicator = false

        view.addSubview(tableViewContentView)
        tableViewContentView.hidden = true
        tableView.addObserver(self, forKeyPath: "bounds", options: .New, context: &tableViewBoundsKVOContext)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &tableViewBoundsKVOContext {
            let height = max(view.frame.height - tableView.contentInset.top, tableView.contentSize.height + tableView.contentInset.bottom)
            tableViewContentView.frame = CGRect(x: 0, y: -tableView.contentOffset.y, width: view.frame.width, height: height)
        } else if context == &titleKVOContext {
            title = (parent as! CellPresentable).text
            parentViewController?.title = title
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    private func setupPlaceholderCell() {
        placeHolderCell.alpha = 0
        placeHolderCell.backgroundView!.backgroundColor = colorForRow(0)
        placeHolderCell.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        tableView.addSubview(placeHolderCell)
        constrain(placeHolderCell) { placeHolderCell in
            placeHolderCell.bottom == placeHolderCell.superview!.topMargin - 7 + 26
            placeHolderCell.left == placeHolderCell.superview!.superview!.left
            placeHolderCell.right == placeHolderCell.superview!.superview!.right
            placeHolderCell.height == tableView.rowHeight
        }
    }

    private func toggleOnboardView(animated animated: Bool = false) {
        if onboardView.superview == nil {
            tableView.addSubview(onboardView)
            onboardView.center = tableView.center
        }

        func updateAlpha() {
            onboardView.alpha = items.isEmpty ? 1 : 0
        }

        if animated {
            UIView.animateWithDuration(0.3, animations: updateAlpha)
        } else {
            updateAlpha()
        }
    }

    // MARK: Notifications

    private func setupFirstSyncWorkaround() {
        // FIXME: Hack to work around sync possibly pulling in a new list.
        // Ideally we'd use ParentType's with primary keys, but those aren't currently supported by sync.
        realmNotificationToken = items.realm!.addNotificationBlock { _, realm in
            var lists = realm.objects(Parent.self)
            if Parent.self == TaskList.self {
                // only merge the initial list
                lists = lists.filter("initial == true")
            }
            guard lists.count > 1 else { return }

            self.realmNotificationToken?.stop()
            self.realmNotificationToken = nil

            let parent = lists.first!

            guard self.parent != parent else { return }

            self.parent = parent

            self.notificationToken?.stop()
            self.notificationToken = nil
            self.setupNotifications()

            // FIXME: Use the Realm's configuration.
            // Currently broken because it doesn't apply the same sync-related values
            // let configuration = realm.configuration

            // Append all other items while deleting their lists, in case they were created locally before sync
            dispatch_async(dispatch_queue_create("io.realm.RealmTasks.bg", nil)) {
                // FIXME: Use the above Realm's configuration.
                // let realm = try! Realm(configuration: configuration)
                let realm = try! Realm()
                try! realm.write {
                    var lists = realm.objects(Parent.self)
                    if Parent.self == TaskList.self {
                        // only merge the initial list
                        lists = lists.filter("initial == true")
                    }
                    while lists.count > 1 {
                        lists.first!.items.appendContentsOf(lists.last!.items)
                        realm.delete(lists.last!)
                    }
                }
            }
        }
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
                    self.tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                    self.tableView.endUpdates()
                }

                if let currentlyEditingIndexPath = self.currentlyEditingIndexPath {
                    UIView.performWithoutAnimation {
                        // FIXME: Updating table view forces resigning first responder
                        // If editing, unintended input state is committed and sync.
                        self.currentlyEditingCell?.temporarilyIgnoreSaveChanges = true
                        updateTableView()
                        let currentlyEditingCell = self.tableView.cellForRowAtIndexPath(currentlyEditingIndexPath) as! TableViewCell<Item>
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
                fatalError(String(error))
            }
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
            return
        }
        let location = recognizer.locationInView(tableView)
        let cell: TableViewCell<Item>!
        if let indexPath = tableView.indexPathForRowAtPoint(location),
            typedCell = tableView.cellForRowAtIndexPath(indexPath) as? TableViewCell<Item> {
            cell = typedCell
            if createBottomViewController != nil && location.x > tableView.bounds.width / 2 {
                navigateToBottomViewController(cell.item)
                return
            }
        } else {
            let row = items.filter("completed = false").count
            try! items.realm?.write {
                items.insert(Item(), atIndex: row)
            }
            let indexPath = NSIndexPath(forRow: row, inSection: 0)
            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            toggleOnboardView(animated: true)
            skipNextNotification()
            cell = tableView.cellForRowAtIndexPath(indexPath) as! TableViewCell<Item>
        }
        let textView = cell.textView
        textView.userInteractionEnabled = !textView.userInteractionEnabled
        textView.becomeFirstResponder()
    }

    func longPressGestureRecognized(recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(location) ?? NSIndexPath(forRow: items.count - 1, inSection: 0)

        switch recognizer.state {
        case .Began:
            guard let cell = tableView.cellForRowAtIndexPath(indexPath) else { break }
            startIndexPath = indexPath
            destinationIndexPath = indexPath

            // Add the snapshot as subview, aligned with the cell
            var center = cell.center
            snapshot = cell.snapshotViewAfterScreenUpdates(false)
            snapshot.layer.shadowColor = UIColor.blackColor().CGColor
            snapshot.layer.shadowOffset = CGSizeMake(-5, 0)
            snapshot.layer.shadowRadius = 5
            snapshot.center = center
            cell.hidden = true
            tableView.addSubview(snapshot)

            // Animate
            let shadowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
            shadowAnimation.fromValue = 0
            shadowAnimation.toValue = 1
            shadowAnimation.duration = 0.3
            snapshot.layer.addAnimation(shadowAnimation, forKey: shadowAnimation.keyPath)
            snapshot.layer.shadowOpacity = 1
            UIView.animateWithDuration(0.3) { [unowned self] in
                center.y = location.y
                self.snapshot.center = center
                self.snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05)
            }
        case .Changed:
            snapshot.center.y = location.y

            if let destinationIndexPath = destinationIndexPath where indexPath != destinationIndexPath && !items[indexPath.row].completed {
                // move rows
                tableView.moveRowAtIndexPath(destinationIndexPath, toIndexPath: indexPath)

                self.destinationIndexPath = indexPath
            }
        case .Ended, .Cancelled, .Failed:
            guard
                let startIndexPath = startIndexPath,
                let destinationIndexPath = destinationIndexPath,
                let cell = tableView.cellForRowAtIndexPath(destinationIndexPath)
            else { break }

            if destinationIndexPath.row != startIndexPath.row && !items[destinationIndexPath.row].completed {
                try! items.realm?.write {
                    items.move(from: startIndexPath.row, to: destinationIndexPath.row)
                }
                skipNextNotification()
            }

            let shadowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
            shadowAnimation.fromValue = 1
            shadowAnimation.toValue = 0
            shadowAnimation.duration = 0.3
            snapshot.layer.addAnimation(shadowAnimation, forKey: shadowAnimation.keyPath)
            snapshot.layer.shadowOpacity = 0

            UIView.animateWithDuration(0.3, animations: { [unowned self] in
                self.snapshot.center = cell.center
                self.snapshot.transform = CGAffineTransformIdentity
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

            self.startIndexPath = nil
            self.destinationIndexPath = nil
        default:
            break;
        }
    }

    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.locationInView(tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) as? TableViewCell<Item> {
            return !cell.item.completed
        }
        return gestureRecognizer.isKindOfClass(UITapGestureRecognizer.self)
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! TableViewCell<Item>
        cell.item = items[indexPath.row]
        cell.itemCompleted = itemCompleted
        cell.itemDeleted = itemDeleted
        cell.cellDidChangeText = cellDidChangeText
        cell.cellDidBeginEditing = cellDidBeginEditing
        cell.cellDidEndEditing = cellDidEndEditing

        if let editingIndexPath = currentlyEditingIndexPath where editingIndexPath.row != indexPath.row {
            cell.alpha = editingCellAlpha
        }

        return cell
    }

    private func cellHeightForText(text: String) -> CGFloat {
        return text.boundingRectWithSize(CGSize(width: view.bounds.size.width - 25, height: view.bounds.size.height),
                                         options: [.UsesLineFragmentOrigin],
                                         attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18)],
                                         context: nil).height + 33
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if currentlyEditingIndexPath?.row == indexPath.row {
            return floor(cellHeightForText(currentlyEditingCell!.textView.text))
        }

        var item = items[indexPath.row]

        // If we are dragging an item around, swap those
        // two items for their appropriate height values
        if let startIndexPath = startIndexPath, destinationIndexPath = destinationIndexPath {
            if indexPath.row == destinationIndexPath.row {
                item = items[startIndexPath.row]
            } else if indexPath.row == startIndexPath.row {
                item = items[destinationIndexPath.row]
            }
        }
        return floor(cellHeightForText(item.text))
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.contentView.backgroundColor = colorForRow(indexPath.row)
        cell.alpha = currentlyEditing ? editingCellAlpha : 1
    }

    private func navigateToBottomViewController(item: Item) {
        bottomViewController = ViewController<Task, TaskList>(
            parent: item as! TaskList,
            colors: UIColor.taskColors()
        )
        startMovingToNextViewController(.Down)
        finishMovingToNextViewController(.Down)
    }

    private func startMovingToNextViewController(direction: NavDirection) {
        let nextVC = direction == .Up ? topViewController! : bottomViewController!
        let parentVC = parentViewController!
        parentVC.addChildViewController(nextVC)
        parentVC.view.insertSubview(nextVC.view, atIndex: 1)
        view.removeAllConstraints()
        nextConstraints = constrain(nextVC.view, tableViewContentView) { nextView, tableViewContentView in
            nextView.size == nextView.superview!.size
            nextView.left == nextView.superview!.left
            if direction == .Up {
                nextView.bottom == tableViewContentView.top - 200
            } else {
                nextView.top == tableViewContentView.bottom + tableView.rowHeight + tableView.contentInset.bottom
            }
        }
        nextVC.didMoveToParentViewController(parentVC)
    }

    private func finishMovingToNextViewController(direction: NavDirection) {
        let nextVC = direction == .Up ? topViewController! : bottomViewController!
        let parentVC = parentViewController!
        willMoveToParentViewController(nil)
        parentVC.title = nextVC.title
        parentVC.view.layoutIfNeeded()
        constrain(nextVC.view, view, replace: nextConstraints!) { nextView, currentView in
            nextView.edges == nextView.superview!.edges
            if direction == .Up {
                currentView.top == nextView.bottom
            } else {
                currentView.bottom == nextView.top
            }
            currentView.size == nextView.size
            currentView.left == nextView.left
        }
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [], animations: {
            parentVC.view.layoutIfNeeded()
        }, completion: { _ in
            self.view.removeFromSuperview()
            nextVC.didMoveToParentViewController(parentVC)
            self.removeFromParentViewController()
        })
    }

    // MARK: UIScrollViewDelegate methods

    func scrollViewDidScroll(scrollView: UIScrollView)  {
        func removeVC(vc: UIViewController?) {
            if scrollView.dragging {
                vc?.view.removeFromSuperview()
                vc?.removeFromParentViewController()
            }
        }

        if distancePulledUp > tableView.rowHeight, let createBottomViewController = createBottomViewController {
            if bottomViewController === parentViewController?.childViewControllers.last { return }
            if bottomViewController == nil {
                bottomViewController = createBottomViewController()
            }
            startMovingToNextViewController(.Down)
            return
        } else {
            removeVC(bottomViewController)
        }

        guard distancePulledDown > 0 else {
            removeVC(topViewController)
            return
        }

        if distancePulledDown <= tableView.rowHeight {
            UIView.animateWithDuration(0.1) {
                self.placeHolderCell.navHintView.alpha = 0
            }
            placeHolderCell.textView.text = "Pull to Create Item"

            let cellHeight = tableView.rowHeight
            let angle = CGFloat(M_PI_2) - tan(distancePulledDown / cellHeight)

            var transform = CATransform3DIdentity
            transform.m34 = 1 / -(1000 * 0.2)
            transform = CATransform3DRotate(transform, angle, 1, 0, 0)

            placeHolderCell.layer.transform = transform

            if items.isEmpty {
                onboardView.alpha = max(0, 1 - (distancePulledDown / cellHeight))
            } else {
                onboardView.alpha = 0
            }
        } else if distancePulledDown <= tableView.rowHeight * 2 {
            UIView.animateWithDuration(0.1) {
                self.placeHolderCell.navHintView.alpha = 0
            }
            placeHolderCell.layer.transform = CATransform3DIdentity
            placeHolderCell.textView.text = "Release to Create Item"
        } else if let createTopViewController = createTopViewController {
            if topViewController === parentViewController?.childViewControllers.last { return }
            if topViewController == nil {
                topViewController = createTopViewController()
            }
            startMovingToNextViewController(.Up)
            placeHolderCell.navHintView.hintText = "Switch to Lists"
            placeHolderCell.navHintView.hintArrowTransfom = CGAffineTransformRotate(CGAffineTransformIdentity, CGFloat(M_PI))

            UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: [], animations: {
                self.placeHolderCell.navHintView.alpha = 1
                self.placeHolderCell.navHintView.hintArrowTransfom  = CGAffineTransformIdentity
            }, completion: nil)

            return
        }

        if scrollView.dragging {
            removeVC(topViewController)
            placeHolderCell.alpha = min(1, distancePulledDown / tableView.rowHeight)
        }
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if distancePulledUp > tableView.rowHeight {
            if bottomViewController === parentViewController?.childViewControllers.last {
                finishMovingToNextViewController(.Down)
            } else {
                let itemsToDelete = items.filter("completed = true")
                let numberOfItemsToDelete = itemsToDelete.count
                guard numberOfItemsToDelete != 0 else { return }

                try! items.realm?.write {
                    for _ in 0..<numberOfItemsToDelete {
                        items.removeLast()
                    }
                    items.realm?.delete(itemsToDelete)
                }
                let startingIndex = items.count
                let indexPathsToDelete = (startingIndex..<(startingIndex + numberOfItemsToDelete)).map { index in
                    return NSIndexPath(forRow: index, inSection: 0)
                }
                tableView.deleteRowsAtIndexPaths(indexPathsToDelete, withRowAnimation: .None)
                skipNextNotification()
                
                vibrate()
            }
            return
        }

        guard distancePulledDown > tableView.rowHeight else { return }

        if distancePulledDown > tableView.rowHeight * 2 &&
            topViewController === parentViewController?.childViewControllers.last {
            finishMovingToNextViewController(.Up)
            return
        }
        // Create new item
        try! items.realm?.write {
            items.insert(Item(), atIndex: 0)
        }
        skipNextNotification()
        tableView.reloadData()
        (tableView.visibleCells.first as! TableViewCell<Item>).textView.becomeFirstResponder()
    }

    // MARK: Cell Callbacks

    private func itemDeleted(item: Item) {
        guard let index = items.indexOf(item) else {
            return
        }

        try! items.realm?.write {
            items.realm?.delete(item)
        }

        tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Left)
        skipNextNotification()
        updateColors()
        toggleOnboardView()
    }

    private func itemCompleted(item: Item) {
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
        try! items.realm?.write {
            items.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
        }

        tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath: destinationIndexPath)
        skipNextNotification()
        updateColors()
        toggleOnboardView()
    }

    private func cellDidBeginEditing(editingCell: TableViewCell<Item>) {
        currentlyEditingCell = editingCell
        currentlyEditingIndexPath = tableView.indexPathForCell(editingCell)

        let editingOffset = editingCell.convertRect(editingCell.bounds, toView: tableView).origin.y - tableView.contentOffset.y - tableView.contentInset.top
        topConstraint?.constant = -editingOffset
        tableView.contentInset.bottom += editingOffset

        placeHolderCell.alpha = 0
        tableView.bounces = false

        UIView.animateWithDuration(0.3, animations: { [unowned self] in
            self.view.layoutSubviews()
            for cell in self.tableView.visibleCells where cell !== editingCell {
                cell.alpha = self.editingCellAlpha
            }
        }, completion: { [unowned self] finished in
            self.tableView.bounces = true
        })
    }

    private func cellDidEndEditing(editingCell: TableViewCell<Item>) {
        currentlyEditingCell = nil
        currentlyEditingIndexPath = nil

        tableView.contentInset.bottom = 54
        topConstraint?.constant = 0
        UIView.animateWithDuration(0.3) { [weak self] in
            guard let strongSelf = self else { return }
            for cell in strongSelf.tableView.visibleCells where cell !== editingCell {
                cell.alpha = 1
            }
            strongSelf.view.layoutSubviews()
        }

        let item = editingCell.item
        if item.text.isEmpty {
            try! item.realm?.write {
                item.realm!.delete(item)
            }
            tableView.deleteRowsAtIndexPaths([tableView.indexPathForCell(editingCell)!], withRowAnimation: .None)
        }
        skipNextNotification()
        toggleOnboardView()
    }

    private func cellDidChangeText(editingCell: TableViewCell<Item>) {
        // If the height of the text view has extended to the next line,
        // reload the height of the cell
        let height = cellHeightForText(editingCell.textView.text)
        if Int(height) != Int(editingCell.frame.size.height) {
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }

            for cell in tableView.visibleCells where cell !== editingCell {
                cell.alpha = editingCellAlpha
            }
        }
    }

    // MARK: Colors

    private func colorForRow(row: Int) -> UIColor {
        let fraction = Double(row) / Double(max(13, items.count))
        return colors.gradientColorAtFraction(fraction)
    }

    private func updateColors(completion completion: (() -> Void)? = nil) {
        let visibleCellsAndColors = tableView.visibleCells.map { cell in
            return (cell, colorForRow(tableView.indexPathForCell(cell)!.row))
        }

        UIView.animateWithDuration(0.5, animations: {
            for (cell, color) in visibleCellsAndColors {
                cell.contentView.backgroundColor = color
            }
        }, completion: { _ in
            completion?()
        })
    }

    // MARK: Sync

    private func skipNextNotification() {
        skipNotification = true
        reloadOnNotification = false
    }
}
