//
//  ItemsInteractor.swift
//  RealmTasks
//
//  Created by Marin Todorov on 9/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import RealmSwift

class ItemsInteractor<Parent: Object where Parent: ListPresentable> {

    let tasks: Tasks<Parent>

    init(parent: Parent) {
        tasks = Tasks(parent: parent)
        
    }
}