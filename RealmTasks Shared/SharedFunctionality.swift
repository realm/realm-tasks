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

import Realm
import RealmSwift

func setupRealmSyncAndInitialList() {
    RLMSyncManager.sharedManager().configureWithAppID(Constants.appID)
    Realm.setGlobalSynchronizationLoggingLevel(.Verbose)

    do {
        let realm = try Realm(configuration: listsRealmConfiguration)
        if realm.isEmpty {
            // Create an initial list if none exist
            try realm.write {
                let list = TaskListReference()
                list.id = Constants.defaultListID
                list.text = Constants.defaultListName
                let listLists = TaskListList()
                listLists.items.append(list)
                realm.add(listLists)
            }
        }
    } catch {
        fatalError("Could not open or write to the realm: \(error)")
    }
}

func openRealmOrLogInWithFunction(logInFunction: () -> ()) {
    if let userRealm = try? Realm(configuration: userRealmConfiguration),
        let token = userRealm.objects(User.self).first?.accessToken {
        try! Realm(configuration: listsRealmConfiguration).open(with: token)
    } else {
        logInFunction()
    }
}

func openRealmAndPersistUserToken(token: String) throws {
    dispatch_async(dispatch_queue_create("io.realm.RealmTasks.bg", nil)) {
        let userRealm = try! Realm(configuration: userRealmConfiguration)
        try! userRealm.write {
            let user = User()
            user.accessToken = token
            userRealm.add(user)
        }
    }
    try Realm(configuration: listsRealmConfiguration).open(with: token)
}
