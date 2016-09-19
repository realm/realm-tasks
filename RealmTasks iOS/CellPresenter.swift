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
}