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
            authenticate(username: username, password: password, register: returnCode == .Register) { error in
                if let error = error {
                    self.presentError(error)
                } else {
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
