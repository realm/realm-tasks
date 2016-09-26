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
        let logInViewController = mainStoryboard.instantiateControllerWithIdentifier("LogInViewController") as! LogInViewController
        logInViewController.delelegate = self

        mainWindowController.contentViewController?.presentViewControllerAsSheet(logInViewController, preventApplicationTermination: false)
    }

    func register() {
        let registerViewController = mainStoryboard.instantiateControllerWithIdentifier("RegisterViewController") as! RegisterViewController
        registerViewController.delegate = self

        mainWindowController.contentViewController?.presentViewControllerAsSheet(registerViewController, preventApplicationTermination: false)
    }

}

extension AppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        mainWindowController = mainStoryboard.instantiateControllerWithIdentifier("MainWindowController") as! NSWindowController
        mainWindowController.window?.titleVisibility = .Hidden
        mainWindowController.showWindow(nil)
        if configureDefaultRealm() {
            let taskListVC = mainWindowController.contentViewController as! TaskListViewController
            taskListVC.items = try! Realm().objects(TaskList.self).first!.items
        } else {
            logIn()
        }
    }

    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindowController.showWindow(nil)

        return true
    }

}

extension AppDelegate {
    func performAuthentication(viewController: NSViewController, username: String, password: String, register: Bool) {
        authenticate(username: username, password: password, register: register) { error in
            // FIXME: Sync API methods callbacks should be executed on main thread
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error {
                    NSApp.presentError(error)
                } else {
                    viewController.dismissController(nil)
                    let taskListVC = (self.mainWindowController.contentViewController as! TaskListViewController)
                    taskListVC.items = try! Realm().objects(TaskList.self).first!.items
                }
            }
        }
    }
}

extension AppDelegate: LogInViewControllerDelegate {

    func logInViewController(viewController: LogInViewController, didLogInWithUserName userName: String, password: String) {
        performAuthentication(viewController, username: userName, password: password, register: false)
    }

    func logInViewControllerDidRegister(viewController: LogInViewController) {
        viewController.dismissController(nil)
        register()
    }

}

extension AppDelegate: RegisterViewControllerDelegate {

    func registerViewController(viewController: RegisterViewController, didRegisterWithUserName userName: String, password: String) {
        performAuthentication(viewController, username: userName, password: password, register: true)
    }

    func registerViewControllerDidCancel(viewController: RegisterViewController) {
        viewController.dismissController(nil)
        logIn()
    }

}

extension NSViewController {

    func presentViewControllerAsSheet(viewController: NSViewController, preventApplicationTermination: Bool) {
        presentViewControllerAsSheet(viewController)
        viewController.view.window?.preventsApplicationTerminationWhenModal = preventApplicationTermination
    }

}
