//
//  ToDoItem.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import RealmSwift

final class ToDoList: Object {
    dynamic var title = ""
    dynamic var order = 0
    let items = List<ToDoItem>()

    convenience init(title: String) {
        self.init()
        self.title = title
    }
}

final class ToDoItem: Object {
    dynamic var text = ""
    dynamic var completed = false

    convenience init(text: String) {
        self.init()
        self.text = text
    }
}
