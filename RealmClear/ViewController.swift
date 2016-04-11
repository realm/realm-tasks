//
//  ViewController.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Cartography
import UIKit

var items =  [
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "Quisque at magna auctor, rhoncus massa sit amet, sodales felis.",
    "Suspendisse consequat purus at dolor ultricies interdum.",
    "In luctus magna aliquet, tincidunt ante et, aliquam tellus.",
    "Suspendisse suscipit lorem ac purus interdum, eu maximus ante pellentesque.",
    "Aenean elementum est ut eros varius posuere vel sit amet eros.",
    "Duis accumsan dolor quis leo tincidunt consectetur.",
    "Proin dictum felis non dui dapibus molestie.",
    "Fusce id est eget erat blandit rutrum.",
    "Fusce rutrum ipsum ac nisi euismod pellentesque.",
    "Nulla venenatis neque id eros consectetur, id pretium turpis sodales.",
    "Nulla in sem pharetra, hendrerit diam ac, mollis nisl.",
    "Nulla nec lectus sed massa tristique maximus.",
    "Cras aliquam velit luctus lacus accumsan, id fringilla eros commodo."
].map(ToDoItem.init)

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

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate, UIGestureRecognizerDelegate {
    let tableView = UITableView()
    var visibleTableViewCells: [TableViewCell] { return tableView.visibleCells as! [TableViewCell] }
    var snapshot: UIView! = nil
    var sourceIndexPath: NSIndexPath? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestureRecognizers()
    }

    // MARK: UI

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    func setupUI() {
        setupTableView()
        setupTitleBar()
    }

    func setupTableView() {
        view.addSubview(tableView)
        constrain(tableView) { tableView in
            tableView.edges == tableView.superview!.edges
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(TableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .None
        tableView.backgroundColor = .blackColor()
        tableView.rowHeight = 54
        tableView.contentInset = UIEdgeInsets(top: 45, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
        tableView.showsVerticalScrollIndicator = false
    }

    func setupTitleBar() {
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

    func setupGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(_:)))
        longPressGestureRecognizer.delegate = self
        tableView.addGestureRecognizer(longPressGestureRecognizer)
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

            // update data source & move rows
            swap(&items[indexPath.row], &items[sourceIndexPath.row])
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
                self.tableView.reloadData()
            })
            break
        }
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

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.rowHeight
    }

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
    }

    // MARK: TableViewCellDelegate

    func itemDeleted(item: ToDoItem) {
        guard let index = items.indexOf({ $0 === item }) else {
            return
        }
        items.removeAtIndex(index)

        // loop over the visible cells to animate delete
        let visibleCells = visibleTableViewCells
        let deletedIndex = visibleCells.indexOf { $0.item === item }
        visibleCells[deletedIndex!].hidden = true
        for cell in visibleCells[deletedIndex!..<visibleCells.count] {
            UIView.animateWithDuration(0.3, delay: 0.01, options: .CurveEaseInOut, animations: {
                cell.frame = CGRectOffset(cell.frame, 0, -cell.frame.size.height)
            }, completion: { [weak self] _ in
                if (cell == visibleCells.last) {
                    self?.tableView.reloadData()
                }
            })
        }
        tableView.beginUpdates()
        let indexPathForRow = NSIndexPath(forRow: index, inSection: 0)
        tableView.deleteRowsAtIndexPaths([indexPathForRow], withRowAnimation: .Fade)
        tableView.endUpdates()
    }

    func itemCompleted(item: ToDoItem) {
        // move cell all the way down
        guard let index = items.indexOf({ $0 === item }) else {
            return
        }
        let sourceIndexPath = NSIndexPath(forRow: index, inSection: 0)
        let destinationIndexPath = NSIndexPath(forRow: items.count - 1, inSection: 0)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) { [unowned self] in
            items.removeAtIndex(sourceIndexPath.row)
            items.insert(item, atIndex: destinationIndexPath.row)
            self.tableView.beginUpdates()
            self.tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath: destinationIndexPath)
            self.tableView.endUpdates()
        }
        let afterMoveToBottomDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(afterMoveToBottomDelay, dispatch_get_main_queue()) { [unowned self] in
            self.tableView.reloadData()
        }
    }
}
