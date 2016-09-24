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

import Foundation
import RealmSwift
import UIKit
import Cartography

class TablePresenter<Parent: Object where Parent: ListPresentable>: NSObject,
    UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {

    var viewController: ViewControllerProtocol! {
        didSet {
            setupMovingGesture()
        }
    }
    weak var cellPresenter: CellPresenter<Parent.Item>?

    var items: List<Parent.Item> {
        return parent.items
    }

    let parent: Parent
    init(parent: Parent, colors: [UIColor]) {
        self.parent = parent
        self.colors = colors
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = viewController.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! TableViewCell<Parent.Item>
        guard let cellPresenter = cellPresenter else {
            return cell
        }

        cell.item = items[indexPath.row]
        cell.presenter = cellPresenter

        if let editingIndexPath = cellPresenter.currentlyEditingIndexPath where editingIndexPath.row != indexPath.row {
            cell.alpha = editingCellAlpha
        }

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let cellPresenter = cellPresenter else {
            return 0.0
        }

        if cellPresenter.currentlyEditingIndexPath?.row == indexPath.row {
            return floor(cellPresenter.cellHeightForText(cellPresenter.currentlyEditingCell!.textView.text))
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
        return floor(cellPresenter.cellHeightForText(item.text))
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.contentView.backgroundColor = colorForRow(indexPath.row)
        guard let cellPresenter = cellPresenter else {
            return
        }
        cell.alpha = cellPresenter.currentlyEditing ? editingCellAlpha : 1
    }

    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let itemCell = cell as! TableViewCell<Parent.Item>
        itemCell.reset()
    }

    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        viewController.scrollViewDidScroll?(scrollView)
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewController.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    // MARK: Moving
    private var snapshot: UIView!
    private var startIndexPath: NSIndexPath?
    private var destinationIndexPath: NSIndexPath?

    func setupMovingGesture() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(_:)))
        longPressGestureRecognizer.delegate = self
        viewController.tableView.addGestureRecognizer(longPressGestureRecognizer)
    }

    func longPressGestureRecognized(recognizer: UILongPressGestureRecognizer) {
        let tableView = viewController.tableView

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
            snapshot.layer.shadowOffset = CGSize(width: -5, height: 0)
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
                    UIView.performWithoutAnimation(tableView.reloadData)
                }
            })

            self.startIndexPath = nil
            self.destinationIndexPath = nil
        default:
            break
        }
    }

    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let tableView = viewController.tableView

        let location = gestureRecognizer.locationInView(tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) as? TableViewCell<Parent.Item> {
            return !cell.item.completed
        }
        return gestureRecognizer.isKindOfClass(UITapGestureRecognizer.self)
    }

    // MARK: Colors
    private let colors: [UIColor]

    func colorForRow(row: Int) -> UIColor {
        let fraction = Double(row) / Double(max(13, items.count))
        return colors.gradientColorAtFraction(fraction)
    }

    func updateColors(completion completion: (() -> Void)? = nil) {
        let tableView = viewController.tableView

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

    // MARK: Placeholder cell
    func setupPlaceholderCell(inTableView tableView: UITableView) -> TableViewCell<Parent.Item> {
        let placeHolderCell = TableViewCell<Parent.Item>(style: .Default, reuseIdentifier: "cell")
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
        return placeHolderCell
    }
}
