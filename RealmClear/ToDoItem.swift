//
//  ToDoItem.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

final class ToDoItem {
    var text: String
    var completed = false

    init(text: String) {
        self.text = text
    }
}
