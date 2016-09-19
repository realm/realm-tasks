//
//  CellPresenter.swift
//  RealmTasks
//
//  Created by Marin Todorov on 9/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

protocol ViewControllerProtocol {
    var tableView: UITableView {get}
    func didUpdateList()

    func setTopConstraintTo(constant constant: CGFloat)
    func setPlaceholderAlpha(alpha: CGFloat)
}

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

    //MARK: Editing

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
            tableView.deleteRowsAtIndexPaths([tableView.indexPathForCell(editingCell)!], withRowAnimation: .None)
        }

        viewController.didUpdateList()
    }

}