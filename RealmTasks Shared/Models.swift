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
import Realm // FIXME: Use Realm Swift once it can create non-synced Realms again.
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
    var text: String {
        get { return String(valueFromList("text")) }
        set { let list = self.list; try! list.realm!.write { list.text = newValue } }
    }
    var completed: Bool {
        get { return (valueFromList("completed") != nil) }
        set { let list = self.list; try! list.realm!.write { list.completed = newValue } } }
    var isCompletable: Bool { return (valueFromList("isCompletable") != nil) }
    var uncompletedCount: Int {
        let items = valueFromList("items") as! Results?
        if items?.count == 0 {
            return 0
        }

        return (items?.filter("completed == false").count)!
    }

    // List Realm Properties
    var listRealmConfiguration: Realm.Configuration {
        let id = self.id
        var configuration = Realm.Configuration()
        configuration.fileURL = Realm.Configuration().fileURL!.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("\(id).realm")
        configuration.objectTypes = [TaskList.self, Task.self]
        configuration.setObjectServerPath(Constants.syncRealmPath + "/\(id)", for: Constants.user)
        return configuration
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
        let listObject = realm.objects(TaskList.self).first!
        return listObject
    }

    func valueFromList(name: String) -> AnyObject? {
        let realm = try! listRealm()
        if realm.isEmpty {
            return nil
        }

        let listObject = realm.objects(TaskList.self).first!
        return listObject.valueForKey(name)
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

// FIXME: Use Realm Swift once it can create non-synced Realms again.
final class PersistedUser: RLMObject {
    // FIXME: Persist access token once https://github.com/realm/realm-cocoa-private/pull/202 is available
    dynamic var username = ""
    dynamic var password = ""
}
