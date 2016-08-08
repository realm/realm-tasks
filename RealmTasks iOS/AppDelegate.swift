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

import RealmSwift
import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        setupRealmSyncAndInitialList()

        window?.rootViewController = ContainerViewController()
        window?.makeKeyAndVisible()

        if let userRealm = try? Realm(configuration: userRealmConfiguration),
            let token = userRealm.objects(User.self).first?.accessToken {
            try! Realm().open(with: token)
        } else {
            logIn()
        }

        return true
    }

    func logIn() {
        let loginManager = RealmSyncLoginManager(authURL: Constants.syncAuthURL, appID: Constants.appID, realmPath: Constants.syncRealmPath)

        loginManager.logIn(fromViewController: window!.rootViewController!) { accessToken, error in
            if let token = accessToken {
                dispatch_async(dispatch_queue_create("io.realm.RealmTasks.bg", nil)) {
                    let userRealm = try! Realm(configuration: userRealmConfiguration)
                    try! userRealm.write {
                        let user = User()
                        user.accessToken = token
                        userRealm.add(user)
                    }
                }
                try! Realm().open(with: token)
                return
            }

            guard let error = error else {
                // This happens when the user chose "Cancel" while logging in, which isn't supported,
                // so just present the login view controller again
                self.logIn()
                return
            }

            // Present error to user

            let alertController = UIAlertController(title: error.localizedDescription, message: error.localizedFailureReason ?? "", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "OK", style: .Default) { _ in
                self.logIn()
            }

            alertController.addAction(defaultAction)
            alertController.preferredAction = defaultAction

            self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}
