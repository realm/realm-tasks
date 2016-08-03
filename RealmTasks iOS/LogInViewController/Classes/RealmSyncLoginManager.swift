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

import UIKit
import CloudKit

public typealias RealmSyncLoginCompletionHandler = (accessToken: String?, error: NSError?) -> Void

public class RealmSyncLoginManager: NSObject {

    let authURL: NSURL
    let appID: String
    let realmPath: String

    private let loginStoryboard = UIStoryboard(name: "RealmSyncLogin", bundle: NSBundle.mainBundle())

    public init(authURL: NSURL, appID: String, realmPath: String) {
        self.authURL = authURL
        self.appID = appID
        self.realmPath = realmPath
    }

    public func logIn(fromViewController parentViewController: UIViewController, completion: RealmSyncLoginCompletionHandler?) {
        guard let logInViewController = loginStoryboard.instantiateInitialViewController() as? LogInViewController else {
            fatalError()
        }

        logInViewController.completionHandler = { userName, password, returnCode in
            switch returnCode {
            case .LogIn:
                self.logIn(userName: userName!, password: password!, completion: completion)
            case .Register:
                self.register(userName: userName!, password: password!, completion: completion)
            case .CloudKit:
                self.connectToCloudKit(completion: completion)
            case .Cancel:
                completion?(accessToken: nil, error: nil)
            }
        }

        parentViewController.presentViewController(logInViewController, animated: true, completion: nil)
    }

    public func logIn(userName userName: String, password: String, completion: RealmSyncLoginCompletionHandler?) {
        let json = [
            "provider": "password",
            "data": userName,
            "password": password,
            "app_id": appID,
            "path": realmPath
        ]

        try! HTTPClient.post(authURL, json: json) { data, response, error in
            if let data = data {
                do {
                    let token = try self.parseResponseData(data)

                    completion?(accessToken: token, error: nil)
                } catch let error as NSError {
                    completion?(accessToken: nil, error: error)
                }
            } else {
                completion?(accessToken: nil, error: error)
            }
        }
    }

    public func register(userName userName: String, password: String, completion: RealmSyncLoginCompletionHandler?) {
        let json = [
            "provider": "password",
            "data": userName,
            "password": password,
            "register": 1,
            "app_id": appID,
            "path": realmPath
        ]

        try! HTTPClient.post(authURL, json: json) { data, response, error in
            if let data = data {
                do {
                    let token = try self.parseResponseData(data)
                    
                    completion?(accessToken: token, error: nil)
                } catch let error as NSError {
                    completion?(accessToken: nil, error: error)
                }
            } else {
                completion?(accessToken: nil, error: error)
            }
        }
    }

    public func connectToCloudKit(completion completion: RealmSyncLoginCompletionHandler?) {
        let container = CKContainer.defaultContainer()

        // Query the private database for an existing access token
        let privateDatabase = container.privateCloudDatabase
        let realmZoneID = CKRecordZoneID(zoneName: "Realm", ownerName: CKOwnerDefaultName)
        let realmTokenRecordID = CKRecordID(recordName: "AccessToken", zoneID: realmZoneID)

        privateDatabase.fetchRecordWithID(realmTokenRecordID) { (record, error) in
            if let error = error {
                switch CKErrorCode(rawValue: error.code)! {
                case .ZoneNotFound: // A Realm specific record zone doesn't exist yet
                    self.registerNewCloudKitUser(completion)
                case .UnknownItem: // The zone exists, but there is no token in it
                    self.registerNewCloudKitUser(completion)
                default:
                    completion?(accessToken: nil, error: error)
                }
                return
            }
        }

//        privateDatabase.fetchRecordZoneWithID(realmZoneID) { (recordZone, error) in
//            if let error = error {
//                completion?(accessToken: nil, error: error)
//                return
//            }
//        }

//        container.fetchUserRecordIDWithCompletionHandler { (recordID, error) in
//            if let error = error {
//                completion?(accessToken: nil, error: error)
//                return
//            }
//
//            self.authenticateCloudKit(recordID?.recordName, completion: completion)
//        }
    }

    public func registerNewCloudKitUser(completion: RealmSyncLoginCompletionHandler?) {
        let container = CKContainer.defaultContainer()

        let authenticationSuccessfulHandler = { (accessToken: String?, error: NSError?) in

            let privateDatabase = container.privateCloudDatabase

            let realmRecordID = CKRecordID(recordName: "DefaultUser")
            let realmRecord = CKRecord(recordType: "RealmSyncSettings", recordID: realmRecordID)
            realmRecord["access_token"] = accessToken

            privateDatabase.saveRecord(realmRecord, completionHandler: { (record, error) in
                completion?(accessToken: accessToken, error: error)
            })
        }

        //First, download our user record name
        let userRecordIDCompletionHandler = { (recordID: CKRecordID?, error: NSError?) in
            if let error = error {
                completion?(accessToken: nil, error: error)
                return
            }

            self.authenticateCloudKit(recordID?.recordName, completion: authenticationSuccessfulHandler)
        }

        container.fetchUserRecordIDWithCompletionHandler(userRecordIDCompletionHandler)
    }

    public func authenticateCloudKit(userRecordID: String?, completion: RealmSyncLoginCompletionHandler?) {
        completion?(accessToken: "0000-0000-0000-0000", error: nil)
        return

        guard let userRecordID = userRecordID else {
            let errorDescription = "iCloud returned a nil user record ID value"
            completion?(accessToken: nil, error: NSError(domain: "io.realm.sync.auth", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription]))
            return
        }

        let json = [
            "provider": "icloud",
            "data": userRecordID,
            "app_id": appID,
            "path": realmPath
        ]

        try! HTTPClient.post(authURL, json: json) { data, response, error in
            if let data = data {
                do {
                    let token = try self.parseResponseData(data)
                    completion?(accessToken: token, error: nil)
                } catch let error as NSError {
                    completion?(accessToken: nil, error: error)
                }
            } else {
                completion?(accessToken: nil, error: error)
            }
        }
    }

    public func logOut() {
        // TODO: implement
    }

    private func parseResponseData(data: NSData) throws -> String {
        let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]

        guard let token = json?["token"] as? String else {
            let errorDescription = json?["error"] as? String ?? "Failed getting token"

            throw NSError(domain: "io.realm.sync.auth", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription])
        }

        return token
    }
}
