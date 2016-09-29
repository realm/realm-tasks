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

protocol ListPresentable {
    associatedtype Item: Object, CellPresentable
    var items: List<Item> { get }
}

protocol CellPresentable {
    var text: String { get set }
    var completed: Bool { get set }
    var isCompletable: Bool { get }
}

final class TaskListList: Object, ListPresentable {
    dynamic var id = 0 // swiftlint:disable:this variable_name
    let items = List<TaskList>()

    override static func primaryKey() -> String? {
        return "id"
    }
}

final class TaskList: Object, CellPresentable, ListPresentable {
    dynamic var id = NSUUID().UUIDString // swiftlint:disable:this variable_name
    dynamic var text = ""
    dynamic var completed = false
    let items = List<Task>()

    var isCompletable: Bool {
        return !items.filter("completed == false").isEmpty
    }

    override static func primaryKey() -> String? {
        return "id"
    }
}

final class Task: Object, CellPresentable {
    dynamic var text = ""
    dynamic var completed = false

    var isCompletable: Bool { return true }

    convenience init(text: String) {
        self.init()
        self.text = text
    }
}
