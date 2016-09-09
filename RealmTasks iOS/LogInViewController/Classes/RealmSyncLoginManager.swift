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

    let cloudKitRecordType = "RealmServer" // The name of the model that will be defined in CloudKit
    let cloudKitRecordID = "io.realm.server.defaultuser" // The primary key-like ID of the object that will hold the access key
    let cloudKitTokenPropertyName = "access_token" // The property of `RealmServer` that will store the access token

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
        let realmTokenRecordID = CKRecordID(recordName: cloudKitRecordID)

        privateDatabase.fetchRecordWithID(realmTokenRecordID) { (record, error) in
            if let error = error {
                switch CKErrorCode(rawValue: error.code)! {
                case .ZoneNotFound, .UnknownItem:
                    self.registerNewCloudKitUser(completion)
                default:
                    completion?(accessToken: nil, error: error)
                }
                return
            }

            completion?(accessToken: String(record?[self.cloudKitTokenPropertyName]), error: error)
        }
    }

    public func registerNewCloudKitUser(completion: RealmSyncLoginCompletionHandler?) {
        let container = CKContainer.defaultContainer()

        //
        let authenticationSuccessfulHandler = { (accessToken: String?, error: NSError?) in
            if let error = error {
                completion?(accessToken: nil, error: error)
                return
            }

            guard accessToken?.characters.count > 0 else {
                let errorDescription = "An error occurred trying to retrieve the access token"
                completion?(accessToken: nil, error: NSError(domain: "io.realm.server.auth", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription]))
                return
            }

            let privateDatabase = container.privateCloudDatabase

            let realmRecordID = CKRecordID(recordName: self.cloudKitRecordID)
            let realmRecord = CKRecord(recordType: self.cloudKitRecordType, recordID: realmRecordID)
            realmRecord[self.cloudKitTokenPropertyName] = accessToken

            let saveRecordsOperation = CKModifyRecordsOperation()
            saveRecordsOperation.recordsToSave = [realmRecord]
            saveRecordsOperation.savePolicy = .IfServerRecordUnchanged
            saveRecordsOperation.modifyRecordsCompletionBlock = { (record, recordID, error) in
                if let error = error {
                    completion?(accessToken: nil, error: error)
                    return
                }

                completion?(accessToken: accessToken, error: error)
            }

            privateDatabase.addOperation(saveRecordsOperation)
        }

        // First, download our user record name
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
        
        guard let userRecordID = userRecordID else {
            let errorDescription = "iCloud returned a nil user record ID value"
            completion?(accessToken: nil, error: NSError(domain: "io.realm.server.auth", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription]))
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
