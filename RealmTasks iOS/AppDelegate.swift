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
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        if configureDefaultRealm() {
            window?.rootViewController = ContainerViewController()
            window?.makeKeyAndVisible()
        } else {
            window?.rootViewController = UIViewController()
            window?.makeKeyAndVisible()
            logIn(animated: false)
        }
        return true
    }

    func logIn(animated animated: Bool = true) {
        let loginStoryboard = UIStoryboard(name: "RealmSyncLogin", bundle: .mainBundle())
        let logInViewController = loginStoryboard.instantiateInitialViewController() as! LogInViewController
        logInViewController.completionHandler = { username, password, returnCode in
            guard returnCode != .Cancel, let username = username, let password = password else {
                // FIXME: handle cancellation properly or just restrict it
                dispatch_async(dispatch_get_main_queue()) {
                    self.logIn()
                }
                return
            }
            authenticate(username, password: password, register: returnCode == .Register) { error in
                if let error = error {
                    self.presentError(error)
                } else {
                    prepopulateInitialList()
                    self.window?.rootViewController = ContainerViewController()
                }
            }
        }
        window?.rootViewController?.presentViewController(logInViewController, animated: false, completion: nil)
    }

    func presentError(error: NSError) {
        let alertController = UIAlertController(title: error.localizedDescription,
                                              message: error.localizedFailureReason ?? "",
                                       preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Try Again", style: .Default) { _ in
            self.logIn()
        })
        self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
    }
}
