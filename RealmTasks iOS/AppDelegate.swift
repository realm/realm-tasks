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

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        setupRealmSyncAndInitialList()
        window?.rootViewController = ContainerViewController()
        window?.makeKeyAndVisible()
        logInWithPersistedUser { error in
            if error != nil {
                // FIXME: Sync API methods callbacs should be executed on main thread
                dispatch_async(dispatch_get_main_queue()) {
                    self.logIn()
                }
            }
        }
        return true
    }

    func logIn() {
        let loginStoryboard = UIStoryboard(name: "RealmSyncLogin", bundle: NSBundle.mainBundle())
        guard let logInViewController = loginStoryboard.instantiateInitialViewController() as? LogInViewController else {
            fatalError()
        }

        logInViewController.completionHandler = { username, password, returnCode in
            if returnCode != .Cancel,
                let username = username,
                let password = password {
                persistUserAndLogInWithUsername(username, password: password, register: returnCode == .Register) { error in
                    if let error = error {
                        // FIXME: Sync API methods callbacs should be executed on main thread
                        dispatch_async(dispatch_get_main_queue()) {
                            self.presentError(error)
                        }
                    }
                }
            } else {
                // FIXME: handle cancellation properly or just restrict it
                dispatch_async(dispatch_get_main_queue()) {
                    self.logIn()
                }
            }
        }
        window?.rootViewController?.presentViewController(logInViewController, animated: true, completion: nil)
    }

    func presentError(error: NSError) {
        // Present error to user
        let alertController = UIAlertController(title: error.localizedDescription, message: error.localizedFailureReason ?? "", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Try Again", style: .Default) { _ in
            self.logIn()
        })
        self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
    }
}
