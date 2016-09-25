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

// Private Helpers

private var realm: Realm! // FIXME: shouldn't have to hold on to the Realm here. https://github.com/realm/realm-sync/issues/694
private var deduplicationNotificationToken: NotificationToken! // FIXME: Remove once core supports ordered sets: https://github.com/realm/realm-core/issues/1206

private func setDefaultRealmConfigurationWithUser(user: User) {
    Realm.Configuration.defaultConfiguration = Realm.Configuration(
        syncConfiguration: (user, Constants.syncServerURL!),
        objectTypes: [TaskListList.self, TaskList.self, Task.self]
    )
    realm = try! Realm()

    if realm.isEmpty {
        try! realm.write {
            let list = TaskList()
            list.id = Constants.defaultListID
            list.text = Constants.defaultListName
            let listLists = TaskListList()
            listLists.items.append(list)
            realm.add(listLists)
        }
    }

    // FIXME: Remove once core supports ordered sets: https://github.com/realm/realm-core/issues/1206
    deduplicationNotificationToken = realm.addNotificationBlock { _, realm in
        guard realm.objects(TaskListList.self).first!.items.count > 1 else {
            return
        }
        // Deduplicate
        dispatch_async(dispatch_queue_create("io.realm.RealmTasks.bg", nil)) {
            let items = try! Realm().objects(TaskListList.self).first!.items
            guard items.count > 1 else { return }

            try! items.realm!.write {
                let listReferenceIDs = NSCountedSet(array: items.map { $0.id })
                for id in listReferenceIDs where listReferenceIDs.countForObject(id) > 1 {
                    let id = id as! String
                    let indexesToRemove = items.enumerate().flatMap { index, element in
                        return element.id == id ? index : nil
                    }
                    indexesToRemove.dropFirst().reverse().forEach(items.removeAtIndex)
                }
            }
        }
    }
}

// Internal Functions

// returns true on success
func configureDefaultRealm() -> Bool {
    if let user = User.all().first {
        setDefaultRealmConfigurationWithUser(user)
        return true
    }
    return false
}

func authenticate(username username: String, password: String, register: Bool, callback: (NSError?) -> ()) {
    User.authenticateWithCredential(.usernamePassword(username, password: password, actions: register ? [.CreateAccount] : []),
                                    authServerURL: Constants.syncAuthURL) { user, error in
        if let user = user {
            setDefaultRealmConfigurationWithUser(user)
        }
        callback(error)
    }
}
