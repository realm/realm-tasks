//
//  CellInteractor.swift
//  RealmTasks
//
//  Created by Marin Todorov on 9/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class CellInteractor<Parent: Object where Parent: ListPresentable> {

    var presenter: ListPresenterProtocol!
    let tasks: Tasks<Parent>

    init(parent: Parent) {
        tasks = Tasks(parent: parent)
    }

    func completeCellItem(item: Parent.Item) {
        guard !(item as Object).invalidated, let index = tasks.parent.items.indexOf(item) else {
            return
        }
        let items = tasks.parent.items

        let sourceIndexPath = NSIndexPath(forRow: index, inSection: 0)
        let destinationIndexPath: NSIndexPath
        if item.completed {
            // move cell to bottom
            destinationIndexPath = NSIndexPath(forRow: items.count - 1, inSection: 0)
        } else {
            // move cell just above the first completed item
            let completedCount = tasks.parent.completedCount
            destinationIndexPath = NSIndexPath(forRow: items.count - completedCount - 1, inSection: 0)
        }
        try! items.realm?.write {
            items.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
        }

        presenter.moveCell(from: sourceIndexPath, to: destinationIndexPath)
    }

    func deleteCellItem(item: Parent.Item) {
        guard let index = tasks.parent.items.indexOf(item) else {
            return
        }
        let items = tasks.parent.items

        try! items.realm?.write {
            items.realm?.delete(item)
        }

        presenter.deleteCell(from: [NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Left)
    }
}