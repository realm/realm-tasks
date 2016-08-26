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
    let items = List<TaskList>()
    dynamic var id = 0

    override static func primaryKey() -> String? {
        return "id"
    }
}

final class TaskList: Object, CellPresentable, ListPresentable {
    dynamic var text = ""
    dynamic var completed = false
    dynamic var id = NSUUID().UUIDString
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

// FIXME: Use Realm Swift once it can create non-synced Realms again.
final class PersistedUser: RLMObject {
    // FIXME: Persist access token once https://github.com/realm/realm-cocoa-private/pull/202 is available
    dynamic var username = ""
    dynamic var password = ""
}
