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

    var currentlyEditingCell: TableViewCell<Item>? {
        didSet {
            viewController.tableView.scrollEnabled = !currentlyEditing
        }
    }
    var currentlyEditingIndexPath: NSIndexPath?

    func cellDidBeginEditing(editingCell: TableViewCell<Item>) {
        guard currentlyEditingCell != editingCell else {
            return
        }
        
        let tableView = viewController.tableView

        currentlyEditingCell = editingCell
        currentlyEditingIndexPath = tableView.indexPathForCell(editingCell)

        let editingOffset = editingCell.becomeEditingCell(inTable: tableView)

        viewController.setTopConstraintTo(constant: -editingOffset)
        viewController.setPlaceholderAlpha(0)
    }

    func cellDidEndEditing(editingCell: TableViewCell<Item>) {
        let tableView = viewController.tableView

        currentlyEditingCell = nil
        currentlyEditingIndexPath = nil

        editingCell.resignEditingCell(inTable: tableView)

        let item = editingCell.item
        guard !(item as Object).invalidated else {
            tableView.reloadData()
            return
        }
        if item.text.isEmpty {
            try! item.realm?.write {
                item.realm!.delete(item)
            }
            tableView.deleteRowsAtIndexPaths([tableView.indexPathForCell(editingCell)!], withRowAnimation: .None)
        }

        viewController.setTopConstraintTo(constant: 0)
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
