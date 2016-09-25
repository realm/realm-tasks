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

import UIKit

public typealias RealmSyncLoginCompletionHandler = (accessToken: String?, error: NSError?) -> Void

public class RealmSyncLoginManager: NSObject {

    let authURL: NSURL
    let appID: String
    let realmPath: String

    private let loginStoryboard: UIStoryboard

    public init(authURL: NSURL, appID: String, realmPath: String) {
        self.authURL = authURL
        self.appID = appID
        self.realmPath = realmPath

        let resourceBundleURL = NSBundle(forClass: LogInViewController.self).URLForResource("RealmSyncAuth", withExtension: "bundle")!

        self.loginStoryboard = UIStoryboard(name: "RealmSyncLogin", bundle: NSBundle(URL: resourceBundleURL))
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
