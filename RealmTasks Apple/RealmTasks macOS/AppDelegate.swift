////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016-2017 Realm Inc.
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

let mainStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)

@NSApplicationMain
class AppDelegate: NSObject {

    fileprivate var mainWindowController: NSWindowController!

    func logIn() {
        let logInViewController = mainStoryboard.instantiateController(withIdentifier:
            NSStoryboard.SceneIdentifier(rawValue: "LogInViewController")) as! LogInViewController
        logInViewController.delelegate = self

        mainWindowController.contentViewController?.presentViewControllerAsSheetPreventingTermination(logInViewController)
    }

    func register(userName: String?) {
        let registerViewController = mainStoryboard.instantiateController(withIdentifier:
            NSStoryboard.SceneIdentifier(rawValue: "RegisterViewController")) as! RegisterViewController
        registerViewController.delegate = self
        registerViewController.userName = userName

        mainWindowController.contentViewController?.presentViewControllerAsSheetPreventingTermination(registerViewController)
    }

    @IBAction func logOut(_ sender: Any? = nil) {
        guard isDefaultRealmConfigured() else {
            return
        }

        let containerViewController = mainWindowController.contentViewController as! ContainerViewController
        containerViewController.dismissAllViewControllers()

        resetDefaultRealm()

        logIn()
    }

    fileprivate func performAuthentication(viewController: NSViewController, username: String, password: String, register: Bool) {
        authenticate(username: username, password: password, register: register) { error in
            DispatchQueue.main.async {
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

extension AppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        mainWindowController = mainStoryboard.instantiateController(withIdentifier:
            NSStoryboard.SceneIdentifier(rawValue: "MainWindowController")) as! NSWindowController
        mainWindowController.window?.titleVisibility = .hidden
        mainWindowController.showWindow(nil)

        setAuthenticationFailureCallback {
            self.logOut()
        }

        if configureDefaultRealm() {
            let containerViewController = mainWindowController.contentViewController as! ContainerViewController
            containerViewController.showRecentList(nil)
        } else {
            logIn()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindowController.showWindow(nil)

        return true
    }

}

extension AppDelegate: LogInViewControllerDelegate {

    func logInViewController(_ viewController: LogInViewController, didLogInWithUserName userName: String, password: String) {
        performAuthentication(viewController: viewController, username: userName, password: password, register: false)
    }

    func logInViewControllerDidRegister(_ viewController: LogInViewController) {
        viewController.dismiss(nil)
        register(userName: viewController.userName)
    }

}

extension AppDelegate: RegisterViewControllerDelegate {

    func registerViewController(_ viewController: RegisterViewController, didRegisterWithUserName userName: String, password: String) {
        performAuthentication(viewController: viewController, username: userName, password: password, register: true)
    }

    func registerViewControllerDidCancel(_ viewController: RegisterViewController) {
        viewController.dismiss(nil)
        logIn()
    }

}

extension NSViewController {

    func presentViewControllerAsSheetPreventingTermination(_ viewController: NSViewController) {
        presentViewControllerAsSheet(viewController)
        viewController.view.window?.preventsApplicationTerminationWhenModal = false
    }

}
