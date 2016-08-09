/*************************************************************************
 *
 * REALM CONFIDENTIAL
 * __________________
 *
 *  [2016] Realm Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of Realm Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to Realm Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Realm Incorporated.
 *
 **************************************************************************/

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
    let items = List<TaskListReference>()
}

final class TaskListReference: Object, CellPresentable {
    // Managed Properties
    dynamic var id = NSUUID().UUIDString

    // Proxied Properties
    var text: String { get { return list.text } set { try! list.realm!.write { list.text = newValue } } }
    var completed: Bool { get { return list.completed } set { try! list.realm!.write { list.completed = newValue } } }
    var isCompletable: Bool { return list.isCompletable }
    var uncompletedCount: Int { return list.items.filter("completed == false").count }

    // List Realm Properties
    var listRealmConfiguration: Realm.Configuration {
        return Realm.Configuration(
            fileURL: Realm.Configuration().fileURL!.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("\(id).realm"),
            syncServerURL: Constants.syncServerURL.URLByAppendingPathComponent(id),
            objectTypes: [TaskList.self, Task.self]
        )
    }
    func listRealm() throws -> Realm {
        return try Realm(configuration: listRealmConfiguration)
    }
    var list: TaskList {
        let realm = try! listRealm()
        // Create list if it doesn't exist
        if realm.isEmpty {
            try! realm.write {
                realm.add(TaskList())
            }
        }
        return realm.objects(TaskList.self).first!
    }
}

final class TaskList: Object, ListPresentable {
    dynamic var text = ""
    dynamic var completed = false
    let items = List<Task>()

    var isCompletable: Bool {
        return !items.filter("completed == false").isEmpty
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

final class User: Object {
    dynamic var accessToken = ""
}
