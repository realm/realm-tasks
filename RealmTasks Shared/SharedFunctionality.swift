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

let user = RealmSwift.User(localIdentity: nil)
func credentialForUsername(username: String, password: String, register: Bool) -> Credential {
    return Credential(credentialToken: username,
                      provider: RLMIdentityProviderUsernamePassword,
                      userInfo: ["password": password, "register": register],
                      serverURL: NSURL(string: "realm://\(Constants.syncHost)"))
}

func setupRealmSyncAndInitialList() {
    configureRealmServerWithAppID(Constants.appID, logLevel: 0, globalErrorHandler: nil)
    syncRealmConfiguration.setObjectServerPath("/~/realmtasks", for: user)
    Realm.Configuration.defaultConfiguration = syncRealmConfiguration

    do {
        let realm = try Realm()
        if realm.isEmpty {
            // Create an initial list if none exist
            try realm.write {
                let list = TaskList()
                list.initial = true
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
