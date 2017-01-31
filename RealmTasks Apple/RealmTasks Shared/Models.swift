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
    var completedCount: Int { get }
    var uncompletedCount: Int { get }
}

protocol CellPresentable {
    var text: String { get set }
    var completed: Bool { get set }
    var isCompletable: Bool { get }
}

extension ListPresentable {
    var uncompletedCount: Int { return items.count - completedCount }
}

final class TaskListList: Object, ListPresentable {
    let items = List<TaskListReference>()
    dynamic var id = 0 // swiftlint:disable:this variable_name
    var completedCount: Int { return 0 }

    override static func primaryKey() -> String? {
        return "id"
    }
}

final class TaskListReference: Object, CellPresentable, ListPresentable {

    // Managed Properties
    dynamic var id = NSUUID().uuidString

    // FIXME: remove textMirror once these two issues have been resolved:
    // https://github.com/realm/realm-sync/issues/703
    // https://github.com/realm/realm-cocoa-private/issues/230
    dynamic var textMirror = ""

    dynamic var fullServerPath: String?

    override static func primaryKey() -> String? {
        return "id"
    }

    // Proxied Properties
    var text: String { get { return list.text } set { try! list.realm!.write { list.text = newValue }; textMirror = newValue } }
    var completed: Bool { get { return list.completed } set { try! list.realm!.write { list.completed = newValue } } }
    var isCompletable: Bool { return list.isCompletable }
    var completedCount: Int { return list.completedCount }
    var uncompletedCount: Int { return list.uncompletedCount }
    var items: List<Task> { return list.items }

    override static func ignoredProperties() -> [String] {
        return ["text", "completed"]
    }

    // List Realm Properties
    var listRealmConfiguration: Realm.Configuration {
        let user = Realm.Configuration.defaultConfiguration.syncConfiguration!.user
        let url = Constants.syncServerURL!.appendingPathComponent((fullServerPath ?? "list-\(id)"))
        return Realm.Configuration(syncConfiguration: SyncConfiguration(user: user, realmURL: url), objectTypes: [TaskList.self, Task.self])
    }
    func listRealm() throws -> Realm {
        return try Realm(configuration: listRealmConfiguration)
    }
    var list: TaskList {
        let realm = try! listRealm()
        // Create list if it doesn't exist
        if realm.isEmpty {
            try! realm.write {
                let list = TaskList()
                list.text = textMirror
                realm.add(list)
            }
        }
        return realm.objects(TaskList.self).first!
    }
}

final class TaskList: Object, CellPresentable, ListPresentable {
    dynamic var id = NSUUID().uuidString // swiftlint:disable:this variable_name
    dynamic var text = ""
    dynamic var completed = false
    //dynamic var id = 0 // swiftlint:disable:this variable_name
    let items = List<Task>()

    var isCompletable: Bool {
        return !items.filter("completed == false").isEmpty
    }
    var completedCount: Int { return items.filter("completed == true").count }

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
