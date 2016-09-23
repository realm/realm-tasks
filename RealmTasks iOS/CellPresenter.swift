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

internal let editingCellAlpha: CGFloat = 0.3

class CellPresenter<Item: Object where Item: CellPresentable> {

    var viewController: ViewControllerProtocol!

    let items: List<Item>
    init(items: List<Item>) {
        self.items = items
    }

    func deleteItem(item: Item) {
        guard !(item as Object).invalidated else {
            return
        }

        guard let index = items.indexOf(item) else {
            return
        }

        try! items.realm?.write {
            items.realm?.delete(item)
        }

        viewController.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Left)
        viewController.didUpdateList()
    }

    func completeItem(item: Item) {
        guard !(item as Object).invalidated, let index = items.indexOf(item) else {
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

        viewController.tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath: destinationIndexPath)
        viewController.didUpdateList()
    }

    // MARK: Editing

    var currentlyEditing: Bool { return currentlyEditingCell != nil }

    private(set) var currentlyEditingCell: TableViewCell<Item>? {
        didSet {
            viewController.tableView.scrollEnabled = !currentlyEditing
        }
    }
    private(set) var currentlyEditingIndexPath: NSIndexPath?

    func cellDidBeginEditing(editingCell: TableViewCell<Item>) {
        currentlyEditingCell = editingCell
        let tableView = viewController.tableView

        currentlyEditingIndexPath = tableView.indexPathForCell(editingCell)

        let editingOffset = editingCell.convertRect(editingCell.bounds, toView: tableView).origin.y - tableView.contentOffset.y - tableView.contentInset.top
        viewController.setTopConstraintTo(constant: -editingOffset)
        tableView.contentInset.bottom += editingOffset

        viewController.setPlaceholderAlpha(0)
        tableView.bounces = false

        UIView.animateWithDuration(0.3, animations: {
            tableView.superview?.layoutSubviews()
            for cell in tableView.visibleCells where cell !== editingCell {
                cell.alpha = editingCellAlpha
            }
        }, completion: {_ in
            tableView.bounces = true
        })
    }

    func cellDidEndEditing(editingCell: TableViewCell<Item>) {
        currentlyEditingCell = nil
        currentlyEditingIndexPath = nil
        let tableView = viewController.tableView

        tableView.contentInset.bottom = 54
        viewController.setTopConstraintTo(constant: 0)
        UIView.animateWithDuration(0.3) {
            for cell in tableView.visibleCells where cell !== editingCell {
                cell.alpha = 1
            }
            tableView.superview?.layoutSubviews()
        }

        let item = editingCell.item
        guard !(item as Object).invalidated else {
            tableView.reloadData()
            return
        }
        if item.text.isEmpty {
            try! item.realm?.write {
                item.realm!.delete(item)
            }
        }

        viewController.didUpdateList()
    }

    func cellDidChangeText(editingCell: TableViewCell<Item>) {
        // If the height of the text view has extended to the next line,
        // reload the height of the cell
        let height = cellHeightForText(editingCell.textView.text)
        let tableView = viewController.tableView

        if Int(height) != Int(editingCell.frame.size.height) {
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }

            for cell in tableView.visibleCells where cell !== editingCell {
                cell.alpha = editingCellAlpha
            }
        }
    }

    func cellHeightForText(text: String) -> CGFloat {
        guard let view = viewController.tableView.superview else {
            return 0.0
        }

        return text.boundingRectWithSize(CGSize(width: view.bounds.size.width - 25, height: view.bounds.size.height),
                                         options: [.UsesLineFragmentOrigin],
                                         attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18)],
                                         context: nil).height + 33
    }
}
