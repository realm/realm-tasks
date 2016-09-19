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
}

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

}