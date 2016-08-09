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
}

extension AppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        setupRealmSyncAndInitialList()

        mainWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateControllerWithIdentifier("MainWindowController") as! NSWindowController
        mainWindowController.window?.titleVisibility = .Hidden
        mainWindowController.showWindow(nil)

        logInWithPersistedUser { error in
            if error != nil {
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
        persistUserAndLogInWithUsername(userName, password: password, register: false) { error in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error {
                    NSApp.presentError(error)
                } else {
                    viewController.dismissController(nil)
                }
            }
        }
    }

    func logInViewControllerDidRegister(viewController: LogInViewController) {
        viewController.dismissController(nil)
        register()
    }

}

extension AppDelegate: RegisterViewControllerDelegate {

    func registerViewController(viewController: RegisterViewController, didRegisterWithUserName userName: String, password: String) {
        persistUserAndLogInWithUsername(userName, password: password, register: true) { error in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error {
                    NSApp.presentError(error)
                } else {
                    viewController.dismissController(nil)
                }
            }
        }
    }

    func registerViewControllerDidCancel(viewController: RegisterViewController) {
        viewController.dismissController(nil)
        logIn()
    }

}
