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

// FIXME: Hack to work around short-lived Realms not syncing.
// https://github.com/realm/realm-sync/issues/694
var syncedRealmsHolder = [Realm]()

final class TaskListList: Object, ListPresentable {
    let items = List<TaskListReference>()
    dynamic var id = 0 // swiftlint:disable:this variable_name

    var completedCount: Int { return 0 }

    override static func primaryKey() -> String? {
        return "id"
    }
}

final class TaskListReference: Object, CellPresentable {
    // Managed Properties
    dynamic var id = NSUUID().UUIDString

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

    override static func ignoredProperties() -> [String] {
        return ["text", "completed"]
    }

    // List Realm Properties
    var listRealmConfiguration: Realm.Configuration {
        let user = Realm.Configuration.defaultConfiguration.syncConfiguration!.user
        let url = Constants.syncServerURL!.URLByAppendingPathComponent(fullServerPath ?? "/~/list-\(id)")
        return Realm.Configuration(syncConfiguration: (user, url), objectTypes: [TaskList.self, Task.self])
    }
    func listRealm() throws -> Realm {
        let realm = try Realm(configuration: listRealmConfiguration)
        syncedRealmsHolder.append(realm)
        return realm
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

final class TaskList: Object, ListPresentable {
    dynamic var text = ""
    dynamic var completed = false
    dynamic var id = 0 // swiftlint:disable:this variable_name
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

final class PersistedUser: Object {
    dynamic var identity = ""
    dynamic var refreshToken = ""
    dynamic var authenticationServer = ""

    var user: User {
        return User(identity: identity, refreshToken: refreshToken, authServerURL: NSURL(string: authenticationServer)!)
    }

    convenience init(user: User) {
        self.init()
        identity = user.identity
        refreshToken = user.refreshToken()
        authenticationServer = user.authenticationServer!.absoluteString
    }
}

// MARK: Sharing

final class ShareOffer: Object {
    dynamic var expires = 0
    dynamic var listName = ""
    dynamic var listPath = ""
    dynamic var token = NSUUID().UUIDString

    var url: String { return "realmtasks://\(token)" }

    override static func primaryKey() -> String {
        return "token"
    }
}

final class ShareRequest: Object {
    dynamic var token = ""

    convenience init(token: String) {
        self.init()
        self.token = token
    }
}
