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

private var deduplicationNotificationToken: NotificationToken! // FIXME: Remove once core supports ordered sets: https://github.com/realm/realm-core/issues/1206

private func setDefaultRealmConfiguration(with user: SyncUser) {
    Realm.Configuration.defaultConfiguration = Realm.Configuration(
        syncConfiguration: SyncConfiguration(user: user, realmURL: Constants.syncServerURL!.appendingPathComponent("~/lists")),
        objectTypes: [TaskListList.self, TaskListReference.self]
    )
    let realm = try! Realm()

    if realm.isEmpty {
        try! realm.write {
            let list = TaskListReference()
            list.id = Constants.defaultListID
            list.text = Constants.defaultListName
            let listLists = TaskListList()
            listLists.items.append(list)
            realm.add(listLists)
        }
    }

    // FIXME: Remove once core supports ordered sets: https://github.com/realm/realm-core/issues/1206
    deduplicationNotificationToken = realm.addNotificationBlock { _, realm in
        let items = realm.objects(TaskListList.self).first!.items
        guard items.count > 1 && !realm.isInWriteTransaction else { return }
        let itemsReference = ThreadSafeReference(to: items)
        // Deduplicate
        DispatchQueue(label: "io.realm.RealmTasks.bg").async {
            let realm = try! Realm(configuration: realm.configuration)
            guard let items = realm.resolve(itemsReference), items.count > 1 else {
                return
            }
            realm.beginWrite()
            let listReferenceIDs = NSCountedSet(array: items.map { $0.id })
            for id in listReferenceIDs where listReferenceIDs.count(for: id) > 1 {
                let id = id as! String
                let indexesToRemove = items.enumerated().flatMap { index, element in
                    return element.id == id ? index : nil
                }
                indexesToRemove.dropFirst().reversed().forEach(items.remove(objectAtIndex:))
            }
            try! realm.commitWrite()
        }
    }
}

// Internal Functions

// returns true on success
func configureDefaultRealm() -> Bool {
    if let user = SyncUser.current {
        setDefaultRealmConfiguration(with: user)
        return true
    }
    return false
}

func authenticate(username: String, password: String, register: Bool, callback: @escaping (NSError?) -> Void) {
    let credentials = SyncCredentials.usernamePassword(username: username, password: password, register: register)
    SyncUser.logIn(with: credentials, server: Constants.syncAuthURL) { user, error in
        DispatchQueue.main.async {
            if let user = user {
                setDefaultRealmConfiguration(with: user)
            }

            let error = error as NSError?

            if let error = error, error._code == SyncError.httpStatusCodeError.rawValue && (error.userInfo["statusCode"] as? Int) == 400 {
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

func openShareURL(_ url: URL) {
    let token = url.absoluteString
        .replacingOccurrences(of: "realmtasks://", with: "")
        .replacingOccurrences(of: "/", with: ":")
    try! SyncUser.current?.acceptShareToken(token)
}

private var acceptShareNotificationToken: NotificationToken?

extension SyncUser {
    fileprivate func acceptShareToken(_ token: String) throws {
        let realm = try managementRealm()
        let response = SyncPermissionOfferResponse(token: token)
        try realm.write {
            realm.add(response)
        }
        acceptShareNotificationToken = realm.objects(SyncPermissionOfferResponse.self).filter("id = %@", response.id).addNotificationBlock { changes in
            print(changes)
            let response: SyncPermissionOfferResponse
            if case let .update(change, _, _, _) = changes, let theResponse = change.first {
                response = theResponse
            } else if case let .initial(change) = changes, let theResponse = change.first {
                response = theResponse
            } else {
                return
            }
            print(response)
            guard response.status == .success, let realmURL = response.realmUrl else { return }
            print(realmURL)
            let defaultRealm = try! Realm()
            let lists = defaultRealm.objects(TaskListList.self).first!.items
            try! defaultRealm.write {
                let listRef = TaskListReference()
                listRef.fullServerPath = realmURL.replacingOccurrences(of: "realm://172.20.20.65:9080", with: "")
                lists.append(listRef)
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
