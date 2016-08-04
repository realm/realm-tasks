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

protocol CellPresentable {
    var realm: Realm? { get }
    var cellText: String { get set }
    static var isCompletable: Bool { get }
    var completed: Bool { get set }
}

final class ToDoListLists: Object {
    let items = List<ToDoList>()
}

final class ToDoList: Object, CellPresentable {
    dynamic var name = ""
    let items = List<ToDoItem>()

    var cellText: String {
        get { return name }
        set { name = newValue }
    }
    static var isCompletable: Bool { return false }
    var completed: Bool {
        get { return false }
        set { /* no-op because isCompletable is false */ }
    }

    override class func ignoredProperties() -> [String] {
        return ["cellText", "completed"]
    }
}

final class ToDoItem: Object, CellPresentable {
    dynamic var text = ""
    dynamic var completed = false

    var cellText: String {
        get { return text }
        set { text = newValue }
    }
    static var isCompletable: Bool { return true }

    override class func ignoredProperties() -> [String] {
        return ["cellText"]
    }

    convenience init(text: String) {
        self.init()
        self.text = text
    }
}

final class User: Object {
    dynamic var accessToken = ""
}
