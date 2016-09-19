//
//  ListPresenter.swift
//  RealmTasks
//
//  Created by Marin Todorov on 9/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

class ListPresenter<Item: Object, Parent: Object where Item: CellPresentable, Parent: ListPresentable, Parent.Item == Item> {

    var cellPresenter: CellPresenter<Item>!
    var tablePresenter: TablePresenter<Parent>!

    var viewController: ViewControllerProtocol! {
        didSet {
            cellPresenter.viewController = viewController
            tablePresenter.viewController = viewController
        }
    }

    let parent: Parent
    init(parent: Parent, colors: [UIColor]) {
        self.parent = parent
        tablePresenter = TablePresenter(parent: parent, colors: colors)
        cellPresenter = CellPresenter(items: parent.items)
    }

}