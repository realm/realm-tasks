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

import Cocoa
import RealmSwift

let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)

@NSApplicationMain
class AppDelegate: NSObject {

    private(set) var mainWindowController: NSWindowController!

    func logIn() {
        let logInViewController = mainStoryboard.instantiateController(withIdentifier: "LogInViewController") as! LogInViewController
        logInViewController.delelegate = self

        mainWindowController.contentViewController?.presentViewControllerAsSheet(viewController: logInViewController, preventApplicationTermination: false)
    }

    func register(userName: String?) {
        let registerViewController = mainStoryboard.instantiateController(withIdentifier: "RegisterViewController") as! RegisterViewController
        registerViewController.delegate = self
        registerViewController.userName = userName

        mainWindowController.contentViewController?.presentViewControllerAsSheet(viewController: registerViewController, preventApplicationTermination: false)
    }

}

extension AppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        mainWindowController = mainStoryboard.instantiateControllerWithIdentifier("MainWindowController") as! NSWindowController
        mainWindowController.window?.titleVisibility = .hidden
        mainWindowController.showWindow(nil)

        if configureDefaultRealm() {
            let containerViewController = mainWindowController.contentViewController as! ContainerViewController
            containerViewController.showRecentList(sender: nil)
        } else {
            logIn()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindowController.showWindow(nil)

        return true
    }

}

extension AppDelegate {
    func performAuthentication(viewController: NSViewController, username: String, password: String, register: Bool) {
        authenticate(username: username, password: password, register: register) { error in
            // FIXME: Sync API methods callbacks should be executed on main thread
            dispatch_get_main_queue().asynchronously() {
                if let error = error {
                    NSApp.presentError(error)
                } else {
                    viewController.dismiss(nil)

                    let containerViewController = self.mainWindowController.contentViewController as! ContainerViewController
                    containerViewController.showRecentList(nil)
                }
            }
        }
    }
}

extension AppDelegate: LogInViewControllerDelegate {

    func logInViewController(viewController: LogInViewController, didLogInWithUserName userName: String, password: String) {
        performAuthentication(viewController: viewController, username: userName, password: password, register: false)
    }

    func logInViewControllerDidRegister(viewController: LogInViewController) {
        viewController.dismiss(nil)
        register(userName: viewController.userName)
    }

}

extension AppDelegate: RegisterViewControllerDelegate {

    func registerViewController(viewController: RegisterViewController, didRegisterWithUserName userName: String, password: String) {
        performAuthentication(viewController: viewController, username: userName, password: password, register: true)
    }

    func registerViewControllerDidCancel(viewController: RegisterViewController) {
        viewController.dismiss(nil)
        logIn()
    }

}

extension NSViewController {

    func presentViewControllerAsSheet(viewController: NSViewController, preventApplicationTermination: Bool) {
        presentViewControllerAsSheet(viewController)
        viewController.view.window?.preventsApplicationTerminationWhenModal = preventApplicationTermination
    }

}
