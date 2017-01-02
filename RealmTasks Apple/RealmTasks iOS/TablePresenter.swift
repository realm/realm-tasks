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

import Cartography
import Foundation
import RealmSwift
import UIKit

private var tableViewBoundsKVOContext = 0

enum PlaceholderState {
    case pullToCreate(distance: CGFloat)
    case releaseToCreate
    case switchToLists
    case alpha(CGFloat)
}

class TablePresenter<Parent: Object where Parent: ListPresentable>: NSObject,
    UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {

    var viewController: ViewControllerProtocol! {
        didSet {
            setupMovingGesture()
        }
    }
    weak var cellPresenter: CellPresenter<Parent.Item>!

    private var items: List<Parent.Item> {
        return parent.items
    }

    private let parent: Parent
    init(parent: Parent, colors: [UIColor]) {
        self.parent = parent
        self.colors = colors
    }

    deinit {
        viewController.tableView.removeObserver(self, forKeyPath: "bounds")
    }

    // MARK: Setup table view

    func setupTableView(inView view: UIView, inout topConstraint: NSLayoutConstraint?, listTitle title: String?) {
        let tableView = viewController.tableView
        let tableViewContentView = viewController.tableViewContentView

        view.addSubview(tableView)
        constrain(tableView) { tableView in
            topConstraint = (tableView.top == tableView.superview!.top)
            tableView.right == tableView.superview!.right
            tableView.bottom == tableView.superview!.bottom
            tableView.left == tableView.superview!.left
        }
        tableView.registerClass(TableViewCell<Parent.Item>.self, forCellReuseIdentifier: "cell")
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
            let tableView = viewController.tableView
            let tableViewContentView = viewController.tableViewContentView
            let view = tableView.superview!
            let height = max(view.frame.height - tableView.contentInset.top, tableView.contentSize.height + tableView.contentInset.bottom)
            tableViewContentView.frame = CGRect(x: 0, y: -tableView.contentOffset.y, width: view.frame.width, height: height)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = viewController.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! TableViewCell<Parent.Item>

        cell.item = items[indexPath.row]
        cell.presenter = cellPresenter

        if let editingIndexPath = cellPresenter.currentlyEditingIndexPath where editingIndexPath.row != indexPath.row {
            cell.alpha = editingCellAlpha
        }

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
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

    private func setupMovingGesture() {
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
            UIGraphicsBeginImageContextWithOptions(cell.frame.size, true, 0)
            cell.layer.renderInContext(UIGraphicsGetCurrentContext()!)
            snapshot = UIImageView(image: UIGraphicsGetImageFromCurrentImageContext()!)
            UIGraphicsEndImageContext()
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

            if let destinationPath = destinationIndexPath where indexPath != destinationPath && !items[indexPath.row].completed {
                // move rows
                tableView.moveRowAtIndexPath(destinationPath, toIndexPath: indexPath)
                destinationIndexPath = indexPath
            }
        case .Ended, .Cancelled, .Failed:
            guard
                let startIndexPath = startIndexPath,
                let destinationIndexPath = destinationIndexPath,
                let cell = tableView.cellForRowAtIndexPath(destinationIndexPath)
                else { break }

            if destinationIndexPath.row != startIndexPath.row && !items[destinationIndexPath.row].completed {
                viewController.uiWriteNoUpdateList {
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

                self.viewController.didUpdateList(reload: false)
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

    // Placeholder cell to use before being adding to the table view
    private let placeHolderCell = TableViewCell<Parent.Item>(style: .Default, reuseIdentifier: "cell")

    func setupPlaceholderCell(inTableView tableView: UITableView) {
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

        constrain(placeHolderCell.contentView, placeHolderCell) { contentView, placeHolderCell in
            contentView.edges == placeHolderCell.edges
        }
    }

    func adjustPlaceholder(state: PlaceholderState) {
        switch state {
            case .pullToCreate(let distancePulledDown):
                UIView.animateWithDuration(0.1) { [unowned self] in
                    self.placeHolderCell.navHintView.alpha = 0
                }
                placeHolderCell.textView.text = "Pull to Create Item"

                let cellHeight = viewController.tableView.rowHeight
                let angle = CGFloat(M_PI_2) - tan(distancePulledDown / cellHeight)

                var transform = CATransform3DIdentity
                transform.m34 = 1 / -(1000 * 0.2)
                transform = CATransform3DRotate(transform, angle, 1, 0, 0)

                placeHolderCell.layer.transform = transform
            case .releaseToCreate:
                UIView.animateWithDuration(0.1) { [unowned self] in
                    self.placeHolderCell.navHintView.alpha = 0
                }
                placeHolderCell.layer.transform = CATransform3DIdentity
                placeHolderCell.textView.text = "Release to Create Item"
            case .switchToLists:
                placeHolderCell.navHintView.hintText = "Switch to Lists"
                placeHolderCell.navHintView.hintArrowTransfom = CGAffineTransformRotate(CGAffineTransformIdentity, CGFloat(M_PI))

                UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5,
                    options: [], animations: { [unowned self] in

                    self.placeHolderCell.navHintView.alpha = 1
                    self.placeHolderCell.navHintView.hintArrowTransfom  = CGAffineTransformIdentity
                }, completion: nil)

            case .alpha(let alpha):
                placeHolderCell.alpha = alpha
        }
    }
}
