//
//  Tasks.swift
//  RealmTasks
//
//  Created by Marin Todorov on 9/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import RealmSwift

class Tasks<Parent: Object where Parent: ListPresentable> {

    private(set) var parent: Parent

    init(parent: Parent) {
        self.parent = parent
    }
}