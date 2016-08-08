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

import Cocoa
import RealmSwift

@NSApplicationMain
class AppDelegate: NSObject {

    private(set) var mainWindowController: NSWindowController!

    func logIn() {
        let logInViewController = NSStoryboard(name: "Main", bundle: nil).instantiateControllerWithIdentifier("LogInViewController") as! LogInViewController
        logInViewController.delelegate = self

        mainWindowController.contentViewController?.presentViewControllerAsSheet(logInViewController)
    }

    func register() {
        let registerViewController = NSStoryboard(name: "Main", bundle: nil).instantiateControllerWithIdentifier("RegisterViewController") as! RegisterViewController
        registerViewController.delegate = self

        mainWindowController.contentViewController?.presentViewControllerAsSheet(registerViewController)
    }

    private func persistRealmUserWithToken(token: String) {
        dispatch_async(dispatch_queue_create("io.realm.RealmTasks.bg", nil)) {
            let userRealm = try! Realm(configuration: userRealmConfiguration)
            try! userRealm.write {
                let user = User()
                user.accessToken = token
                userRealm.add(user)
            }
        }
    }

    private func restorePersistedRealmUser() -> Bool {
        guard let userRealm = try? Realm(configuration: userRealmConfiguration), let token = userRealm.objects(User.self).first?.accessToken else {
            return false
        }

        return (try? Realm().open(with: token)) == nil
    }
}

extension AppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        setupRealmSyncAndInitialList()

        mainWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateControllerWithIdentifier("MainWindowController") as! NSWindowController
        mainWindowController.window?.titleVisibility = .Hidden
        mainWindowController.showWindow(nil)

        if !restorePersistedRealmUser() {
            dispatch_async(dispatch_get_main_queue()) {
                self.logIn()
            }
        }
    }

    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindowController.showWindow(nil)

        return true
    }

}

extension AppDelegate: LogInViewControllerDelegate {

    func logInViewController(viewController: LogInViewController, didLogInWithUserName userName: String, password: String) {
        // FIXME: Use Realm convenience auth API insead (https://github.com/realm/realm-cocoa-private/issues/187)
        logIn(userName: userName, password: password, register: false) { accessToken, error in
            if let error = error {
                NSApp.presentError(error)
            } else {
                if let token = accessToken {
                    self.persistRealmUserWithToken(token)

                    do {
                        try Realm().open(with: token)
                        viewController.dismissController(nil)
                    } catch let error as NSError {
                        NSApp.presentError(error)
                    }
                }
            }
        }

//        try! Realm().open(for: userName, password: password, newAccount: false) { error, session in
//            // FIXME: Completion handler is executed on the background thread
//            dispatch_async(dispatch_get_main_queue()) {
//                if let error = error {
//                    NSApp.presentError(error)
//                } else {
//                    viewController.dismissController(nil)
//                }
//            }
//        }
    }

    func logInViewControllerDidRegister(viewController: LogInViewController) {
        viewController.dismissController(nil)
        register()
    }

}

extension AppDelegate: RegisterViewControllerDelegate {

    func registerViewController(viewController: RegisterViewController, didRegisterWithUserName userName: String, password: String) {
        // FIXME: Use Realm convenience auth API insead (https://github.com/realm/realm-cocoa-private/issues/187)
        logIn(userName: userName, password: password, register: true) { accessToken, error in
            if let error = error {
                NSApp.presentError(error)
            } else {
                if let token = accessToken {
                    self.persistRealmUserWithToken(token)

                    do {
                        try Realm().open(with: token)
                        viewController.dismissController(nil)
                    } catch let error as NSError {
                        NSApp.presentError(error)
                    }
                }
            }
        }

//        try! Realm().open(for: userName, password: password, newAccount: true) { error, session in
//            // FIXME: Completion handler is executed on the background thread
//            dispatch_async(dispatch_get_main_queue()) {
//                if let error = error {
//                    NSApp.presentError(error)
//                } else {
//                    viewController.dismissController(nil)
//                }
//            }
//        }
    }

    func registerViewControllerDidCancel(viewController: RegisterViewController) {
        viewController.dismissController(nil)
        logIn()
    }

}

private extension AppDelegate {

    private func logIn(userName userName: String, password: String, register: Bool, completion: ((accessToken: String?, error: NSError?) -> Void)?) {
        let json = [
            "provider": "password",
            "data": userName,
            "password": password,
            "register": register,
            "app_id": Constants.appID,
            "path": Constants.syncRealmPath
        ]

        try! HTTPClient.post(Constants.syncAuthURL, json: json) { data, response, error in
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

    private func parseResponseData(data: NSData) throws -> String {
        let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]

        guard let token = json?["token"] as? String else {
            let errorDescription = json?["error"] as? String ?? "Failed getting token"

            throw NSError(domain: "io.realm.sync.auth", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription])
        }

        return token
    }

}
