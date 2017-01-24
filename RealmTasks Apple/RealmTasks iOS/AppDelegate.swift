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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        setAuthenticationFailureCallback {
            resetDefaultRealm()
            self.window?.rootViewController = UIViewController()
            self.logIn()
        }

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

    func logIn(animated: Bool = true) {
        let loginStoryboard = UIStoryboard(name: "RealmSyncLogin", bundle: .main)
        let logInViewController = loginStoryboard.instantiateInitialViewController() as! LogInViewController
        logInViewController.completionHandler = { response in
            guard response.returnCode != .cancel, let username = response.username, let password = response.password else {
                // FIXME: handle cancellation properly or just restrict it
                DispatchQueue.main.async {
                    self.logIn()
                }
                return
            }
            authenticate(username: username, password: password, register: response.returnCode == .register) { error in
                if let error = error {
                    self.present(error: error)
                } else {
                    self.window?.rootViewController = ContainerViewController()
                }
            }
        }
        window?.rootViewController?.present(logInViewController, animated: false, completion: nil)
    }

    func present(error: NSError) {
        let alertController = UIAlertController(title: error.localizedDescription,
                                                message: error.localizedFailureReason ?? "",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
            self.logIn()
        })
        window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}
