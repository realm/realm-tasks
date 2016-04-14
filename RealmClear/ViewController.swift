//
//  ViewController.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

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

// MARK: View Controller

final class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate, UIGestureRecognizerDelegate {

    // MARK: Properties

    // Stored Properties
    private var items = try! Realm().objects(ToDoList).first!.items
    private let tableView = UITableView()
    private var visibleTableViewCells: [TableViewCell] { return tableView.visibleCells as! [TableViewCell] }
    private var realmNotificationToken: NotificationToken!

    // Scrolling
    var distancePulledDown: CGFloat {
        return -tableView.contentOffset.y - tableView.contentInset.top
    }
    var distancePulledUp: CGFloat {
        return tableView.contentOffset.y + tableView.bounds.size.height - max(tableView.bounds.size.height, tableView.contentSize.height)
    }

    // Moving
    private var snapshot: UIView! = nil
    private var sourceIndexPath: NSIndexPath? = nil

    // Editing
    private var currentlyEditing = false {
        didSet {
            tableView.scrollEnabled = !currentlyEditing
        }
    }
    private var topConstraint: NSLayoutConstraint?

    // Placeholder cell to use before being adding to the table view
    private let placeHolderCell = TableViewCell(style: .Default, reuseIdentifier: "cell")

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestureRecognizers()
        setupRealmNotifications()
    }

    // MARK: UI

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    private func setupUI() {
        setupTableView()
        setupPlaceholderCell()
        setupTitleBar()
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
        placeHolderCell.backgroundColor = UIColor(red: 0.85, green: 0, blue: 0, alpha: 1)
        tableView.addSubview(placeHolderCell)
        constrain(placeHolderCell) { placeHolderCell in
            placeHolderCell.bottom == placeHolderCell.superview!.topMargin - 7
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
        titleLabel.text = "List Title"
        titleLabel.textColor = .whiteColor()
        titleBar.addSubview(titleLabel)
        constrain(titleLabel) { titleLabel in
            titleLabel.left == titleLabel.superview!.left
            titleLabel.right == titleLabel.superview!.right
            titleLabel.bottom == titleLabel.superview!.bottom - 5
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
            tableView.endEditing(true)
        } else if let indexPath = tableView.indexPathForRowAtPoint(recognizer.locationInView(tableView)),
            cell = tableView.cellForRowAtIndexPath(indexPath) as? TableViewCell {
            cell.textView.userInteractionEnabled = !cell.textView.userInteractionEnabled
            cell.textView.becomeFirstResponder()
        }
    }

    func longPressGestureRecognized(recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(location)
        switch recognizer.state {
        case .Possible: break
        case .Began:
            guard let indexPath = indexPath, cell = tableView.cellForRowAtIndexPath(indexPath) else { break }
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

            guard let indexPath = indexPath, sourceIndexPath = sourceIndexPath
                where indexPath != sourceIndexPath else { break }

            items.realm!.beginWriteIgnoringNotifications()
            // update data source & move rows
            items.move(from: indexPath.row, to: sourceIndexPath.row)
            try! items.realm!.commitWrite()
            tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath: indexPath)
            self.sourceIndexPath = indexPath
            break
        case .Ended, .Cancelled, .Failed:
            guard let indexPath = indexPath, cell = tableView.cellForRowAtIndexPath(indexPath) else { break }
            UIView.animateWithDuration(0.3, animations: { [unowned self] in
                self.snapshot.center = cell.center
                self.snapshot.transform = CGAffineTransformIdentity
                self.snapshot.layer.shadowOpacity = 0
            }, completion: { [unowned self] _ in
                cell.hidden = false
                self.sourceIndexPath = nil
                self.snapshot.removeFromSuperview()
                self.snapshot = nil
                let visibleIndexPaths = self.visibleTableViewCells.flatMap(self.tableView.indexPathForCell)
                self.tableView.reloadRowsAtIndexPaths(visibleIndexPaths, withRowAnimation: .None)
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

    // MARK: Realm

    func setupRealmNotifications() {
        realmNotificationToken = items.addNotificationBlock { [unowned self] (change: RealmCollectionChangePaths) in
            switch change {
            case .Initial:
                // Results are now populated and can be accessed without blocking the UI
                self.tableView.reloadData()
                break
            case .Update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the table view
                self.tableView.beginUpdates()
                self.tableView.insertRowsAtIndexPaths(insertions, withRowAnimation: .None)
                self.tableView.deleteRowsAtIndexPaths(deletions, withRowAnimation: .None)
                self.tableView.reloadRowsAtIndexPaths(modifications, withRowAnimation: .None)
                self.tableView.endUpdates()

                if insertions.map({ $0.row }) == [0],
                    let textView = self.visibleTableViewCells.first?.textView {
                    // new item was added, let's edit it
                    textView.userInteractionEnabled = true
                    textView.becomeFirstResponder()
                }
                break
            case .Error(let error):
                // An error occured while opening the Realm file on the background worker thread
                fatalError("\(error)")
                break
            }
        }
    }

    deinit {
        realmNotificationToken.stop()
        realmNotificationToken = nil
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! TableViewCell
        cell.item = items[indexPath.row]
        cell.delegate = self
        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let text = items[indexPath.row].text as NSString
        let height = text.boundingRectWithSize(view.bounds.size,
                                               options: [.UsesLineFragmentOrigin],
                                               attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18)],
                                               context: nil).height
        return height + 32
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let rowFloat = CGFloat(indexPath.row)
        cell.backgroundColor = UIColor(red: 0.85 + (0.005 * rowFloat),
                                       green: 0.07 + (0.04 * rowFloat), blue: 0.1, alpha: 1)
        cell.alpha = currentlyEditing ? 0.3 : 1
    }

    // MARK: UIScrollViewDelegate methods

    func scrollViewDidScroll(scrollView: UIScrollView)  {
        guard distancePulledDown > 0 else { return }

        placeHolderCell.textView.text = distancePulledDown > tableView.rowHeight ?
            "Release to Create Item" : "Pull to Create Item"
        placeHolderCell.alpha = min(1, distancePulledDown / tableView.rowHeight)
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if distancePulledUp > 160 {
            let itemsToDelete = items.filter("completed = true")
            guard !itemsToDelete.isEmpty else { return }

            try! items.realm?.write {
                items.realm?.delete(itemsToDelete)
            }

            vibrate()
        } else if distancePulledDown > tableView.rowHeight {
            try! items.realm?.write {
                items.insert(ToDoItem(text: ""), atIndex: 0)
            }
        }
    }

    // MARK: TableViewCellDelegate

    func itemDeleted(item: ToDoItem) {
        try! items.realm?.write {
            items.realm?.delete(item)
        }

        visibleTableViewCells.filter({ $0.item === item }).first?.hidden = true
        delay(0.2) { [weak self] in self?.updateColors() }
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
        }
        delay(0.5) { [weak self] in self?.updateColors() }
    }

    func cellDidBeginEditing(editingCell: TableViewCell) {
        currentlyEditing = true
        let editingOffset = editingCell.convertRect(editingCell.bounds, toView: tableView).origin.y
        topConstraint?.constant = -editingOffset
        UIView.animateWithDuration(0.3) { [unowned self] in
            self.view.layoutSubviews()
            for cell in self.visibleTableViewCells where cell !== editingCell {
                cell.alpha = 0.3
            }
        }
    }

    func cellDidEndEditing(editingCell: TableViewCell) {
        currentlyEditing = false
        topConstraint?.constant = 0
        UIView.animateWithDuration(0.3) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.view.layoutSubviews()
            for cell in strongSelf.visibleTableViewCells where cell !== editingCell {
                cell.alpha = 1
            }
        }
        if let item = editingCell.item where item.text.isEmpty {
            itemDeleted(item)
        }
    }

    // MARK: Actions

    private func updateColors() {
        let visibleIndexPaths = visibleTableViewCells.flatMap(tableView.indexPathForCell)
        tableView.reloadRowsAtIndexPaths(visibleIndexPaths, withRowAnimation: .None)
    }
}
