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

import Foundation
import RealmSwift
import UIKit

internal let editingCellAlpha: CGFloat = 0.3

class CellPresenter<Item: Object> where Item: CellPresentable {

    var viewController: ViewControllerProtocol!

    let items: List<Item>
    init(items: List<Item>) {
        self.items = items
    }

    func deleteItem(item: Item) {
        try! items.realm?.write {
            guard !(item as Object).isInvalidated, let index = items.index(of: item) else {
                return
            }

            items.realm?.delete(item)
            viewController.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
            viewController.didUpdateList()
        }
    }

    func completeItem(item: Item) {
        try! items.realm?.write {
            guard !(item as Object).isInvalidated, let index = items.index(of: item) else {
                return
            }

            let sourceIndexPath = IndexPath(row: index, section: 0)
            let destinationIndexPath: IndexPath
            if item.completed {
                // move cell to bottom
                destinationIndexPath = IndexPath(row: items.count - 1, section: 0)
            } else {
                // move cell just above the first completed item
                let completedCount = items.filter("completed = true").count
                destinationIndexPath = IndexPath(row: items.count - completedCount - 1, section: 0)
            }

            items.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
            viewController.tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
            viewController.didUpdateList()
        }
    }

    // MARK: Editing

    var currentlyEditing: Bool { return currentlyEditingCell != nil }

    private(set) var currentlyEditingCell: TableViewCell<Item>? {
        didSet {
            viewController.tableView.isScrollEnabled = !currentlyEditing
        }
    }
    private(set) var currentlyEditingIndexPath: IndexPath?

    func cellDidBeginEditing(editingCell: TableViewCell<Item>) {
        currentlyEditingCell = editingCell
        let tableView = viewController.tableView

        currentlyEditingIndexPath = tableView.indexPath(for: editingCell)

        let editingOffset = editingCell.convert(rect: editingCell.bounds, toView: tableView).origin.y - tableView.contentOffset.y - tableView.contentInset.top
        viewController.setTopConstraintTo(constant: -editingOffset)
        tableView.contentInset.bottom += editingOffset

        viewController.setPlaceholderAlpha(alpha: 0)
        tableView.bounces = false

        UIView.animate(withDuration: 0.3, animations: {
            tableView.superview?.layoutSubviews()
            for cell in tableView.visibleCells where cell !== editingCell {
                cell.alpha = editingCellAlpha
            }
        }, completion: { _ in
            tableView.bounces = true
        })
    }

    func cellDidEndEditing(editingCell: TableViewCell<Item>) {
        currentlyEditingCell = nil
        currentlyEditingIndexPath = nil
        let tableView = viewController.tableView

        tableView.contentInset.bottom = 54
        viewController.setTopConstraintTo(constant: 0)
        UIView.animate(withDuration: 0.3) {
            for cell in tableView.visibleCells where cell !== editingCell {
                cell.alpha = 1
            }
            tableView.superview?.layoutSubviews()
        }

        let item = editingCell.item
        guard !(item as! Object).isInvalidated else {
            tableView.reloadData()
            return
        }
        if (item?.text.isEmpty)! {
            try! item?.realm?.write {
                item?.realm!.delete(item!)
            }
        }

        viewController.didUpdateList()
    }

    func cellDidChangeText(editingCell: TableViewCell<Item>) {
        // If the height of the text view has extended to the next line,
        // reload the height of the cell
        let height = cellHeightForText(text: editingCell.textView.text)
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
            return 0
        }

        return text.boundingRect(with: CGSize(width: view.bounds.size.width - 25, height: view.bounds.size.height),
                                         options: [.usesLineFragmentOrigin],
                                         attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18)],
                                         context: nil).height + 33
    }
}
