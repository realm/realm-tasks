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

// Private Helpers

private var realm: Realm! // FIXME: shouldn't have to hold on to the Realm here. https://github.com/realm/realm-sync/issues/694
private var deduplicationNotificationToken: NotificationToken! // FIXME: Remove once core supports ordered sets: https://github.com/realm/realm-core/issues/1206

private var authenticationFailureCallback: (() -> ())?

private func setDefaultRealmConfigurationWithUser(user: SyncUser) {
    SyncManager.sharedManager().errorHandler = { error, session in
        // FIXME: remove after SyncManager starts output log for errors
        Swift.print("SyncManager error: \(error)")

        // FIXME: handle errors properly after bindings provide better error reporting
        if session == nil {
            authenticationFailureCallback?()
        }
    }

    Realm.Configuration.defaultConfiguration = Realm.Configuration(
        syncConfiguration: SyncConfiguration(user: user, realmURL: Constants.syncServerURL!),
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

func isDefaultRealmConfigured() -> Bool {
    return !realm.isEmpty
}

// returns true on success
func configureDefaultRealm() -> Bool {
    if let user = SyncUser.currentUser() {
        setDefaultRealmConfigurationWithUser(user)
        return true
    }
    return false
}

func resetDefaultRealm() {
    guard let user = SyncUser.all().first else {
        return
    }

    deduplicationNotificationToken.stop()
    realm = nil

    user.logOut()
}

func setAuthenticationFailureCallback(callback: (() -> Void)?) {
    authenticationFailureCallback = callback
}

func authenticate(username username: String, password: String, register: Bool, callback: (NSError?) -> ()) {
    SyncUser.logInWithCredentials(.usernamePassword(username, password: password, register: register),
                                  authServerURL: Constants.syncAuthURL) { user, error in
        dispatch_async(dispatch_get_main_queue()) {
            if let user = user {
                setDefaultRealmConfigurationWithUser(user)
            }

            if let error = error where error.code == SyncError.HTTPStatusCodeError.rawValue && (error.userInfo["statusCode"] as? Int) == 400 {
                // FIXME: workararound for https://github.com/realm/realm-cocoa-private/issues/204
                let improvedError = NSError(error: error,
                                            description: "Incorrect username or password.",
                                            recoverySuggestion: "Please check username and password or register a new account.")
                callback(improvedError)
            } else {
                callback(error)
            }
        }
    }
}

private extension NSError {

    convenience init(error: NSError, description: String?, recoverySuggestion: String?) {
        var userInfo = error.userInfo

        userInfo[NSLocalizedDescriptionKey] = description
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion

        self.init(domain: error.domain, code: error.code, userInfo: userInfo)
    }

}
