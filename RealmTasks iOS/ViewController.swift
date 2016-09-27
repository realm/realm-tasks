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

private enum NavDirection {
    case Up, Down
}

// MARK: View Controller Protocol
protocol ViewControllerProtocol: UIScrollViewDelegate {
    var tableView: UITableView {get}
    var tableViewContentView: UIView {get}
    var view: UIView! {get}

    func didUpdateList()

    func setTopConstraintTo(constant constant: CGFloat)
    func setPlaceholderAlpha(alpha: CGFloat)

    func setListTitle(title: String)

    func removeFromParentViewController()
}

// MARK: View Controller

// FIXME: This class should be split up.
// swiftlint:disable type_body_length
final class ViewController<Item: Object, Parent: Object where Item: CellPresentable, Parent: ListPresentable, Parent.Item == Item>:
    UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate, ViewControllerProtocol {

    // MARK: Properties
    var items: List<Item> {
        return listPresenter.parent.items
    }

    // Table View
    let tableView = UITableView()
    internal let tableViewContentView = UIView()

    // Notifications
    private var notificationToken: NotificationToken?

    // Scrolling
    private var distancePulledDown: CGFloat {
        return -tableView.contentOffset.y - tableView.contentInset.top
    }
    private var distancePulledUp: CGFloat {
        return tableView.contentOffset.y + tableView.bounds.size.height - max(tableView.bounds.size.height, tableView.contentSize.height)
    }

    // Auto Layout
    private var topConstraint: NSLayoutConstraint?
    private var nextConstraints: ConstraintGroup?

    // Placeholder cell to use before being adding to the table view
    private let placeHolderCell = TableViewCell<Item>(style: .Default, reuseIdentifier: "cell")

    // Onboard view
    private let onboardView = OnboardView()

    // Top/Bottom View Controllers
    private let createTopViewController: (() -> (UIViewController))?
    private var topViewController: UIViewController?
    private let createBottomViewController: (() -> (UIViewController))?
    private var bottomViewController: UIViewController?

    // MARK: MTT
    private var listPresenter: ListPresenter<Item, Parent>!

    // MARK: View Lifecycle

    init(parent: Parent, colors: [UIColor]) {
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

        listPresenter = ListPresenter(parent: parent, colors: colors)
        listPresenter.viewController = self
    }

    deinit {
        tableView.removeObserver(self, forKeyPath: "bounds")
        notificationToken?.stop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
        tableView.dataSource = listPresenter.tablePresenter
        tableView.delegate = listPresenter.tablePresenter
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
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    override func didMoveToParentViewController(parent: UIViewController?) {
        guard parent == nil else { // we're being removed from our parent controller
            return
        }

        let visibleCells = tableView.visibleCells
        for cell in visibleCells {
            (cell as! TableViewCell<Item>).reset()
        }
    }

    private func setupPlaceholderCell() {
        placeHolderCell.alpha = 0
        placeHolderCell.backgroundView!.backgroundColor = listPresenter.tablePresenter.colorForRow(0)
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

    private func setupNotifications() {
        notificationToken = items.addNotificationBlock { [unowned self] changes in
            // Do not perform an update if the user is editing a cell at this moment
            // (The table will be reloaded by the 'end editing' call of the active cell)
            guard self.listPresenter.cellPresenter.currentlyEditingCell == nil else {
                return
            }

            self.tableView.reloadData()
        }
    }

    // MARK: Gesture Recognizers

    private func setupGestureRecognizers() {
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(_:))))
    }

    func tapGestureRecognized(recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .Ended else {
            return
        }
        if listPresenter.cellPresenter.currentlyEditing {
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
            var row: Int = 0
            try! items.realm?.write {
                row = items.filter("completed = false").count
                items.insert(Item(), atIndex: row)
            }
            let indexPath = NSIndexPath(forRow: row, inSection: 0)
            tableView.reloadData()
            toggleOnboardView(animated: true)
            cell = tableView.cellForRowAtIndexPath(indexPath) as! TableViewCell<Item>
        }
        let textView = cell.textView
        textView.userInteractionEnabled = !textView.userInteractionEnabled
        textView.becomeFirstResponder()
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
        }, completion: { [unowned self] _ in
            self.view.removeFromSuperview()
            nextVC.didMoveToParentViewController(parentVC)
            self.removeFromParentViewController()
        })
    }

    // MARK: UIScrollViewDelegate methods

    // FIXME: This could easily be refactored to avoid such a high CC.
    // swiftlint:disable:next cyclomatic_complexity
    func scrollViewDidScroll(scrollView: UIScrollView) {
        func removeVC(viewController: UIViewController?) {
            if scrollView.dragging {
                viewController?.view.removeFromSuperview()
                viewController?.removeFromParentViewController()
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
            UIView.animateWithDuration(0.1) { [unowned self] in
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
            UIView.animateWithDuration(0.1) { [unowned self] in
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

            UIView.animateWithDuration(0.4, delay: 0.0,
                                       usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5,
                                       options: [], animations: { [unowned self] in
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
                try! items.realm?.write { [unowned self] in
                    let itemsToDelete = self.items.filter("completed = true")
                    let numberOfItemsToDelete = itemsToDelete.count
                    guard numberOfItemsToDelete != 0 else { return }

                    self.items.realm?.delete(itemsToDelete)

                    vibrate()
                }
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
        tableView.reloadData()

        if let firstCell = tableView.visibleCells.first as? TableViewCell<Item> {
            firstCell.textView.becomeFirstResponder()
        }
    }

    // MARK: ViewControllerProtocol
    func didUpdateList() {
        listPresenter.tablePresenter.updateColors()
        tableView.reloadData()
        toggleOnboardView()
    }

    func setTopConstraintTo(constant constant: CGFloat) {
        topConstraint?.constant = constant
    }

    func setPlaceholderAlpha(alpha: CGFloat) {
        placeHolderCell.alpha = alpha
    }

    func setListTitle(title: String) {
        self.title = title
        parentViewController?.title = title
    }
}
