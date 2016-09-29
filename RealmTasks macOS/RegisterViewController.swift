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

protocol RegisterViewControllerDelegate: class {

    func registerViewController(viewController: RegisterViewController, didRegisterWithUserName userName: String, password: String)
    func registerViewControllerDidCancel(viewController: RegisterViewController)

}

class RegisterViewController: NSViewController {

    @IBOutlet private weak var userNameTextField: NSTextField!
    @IBOutlet private weak var passwordTextField: NSTextField!
    @IBOutlet private weak var confirmationTextField: NSTextField!

    weak var delegate: RegisterViewControllerDelegate?

    var userName: String?
    var password: String?
    var confirmation: String?

    var confirmationMatchesPassword: Bool {
        return password == confirmation
    }

    // Some KVO magic, see https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVODependentKeys.html
    static func keyPathsForValuesAffectingConfirmationMatchesPassword() -> NSSet {
        return NSSet(array: ["password", "confirmation"])
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        if userName?.isEmpty == false {
            view.window?.initialFirstResponder = passwordTextField
            view.window?.recalculateKeyViewLoop()
        }
    }

    @IBAction func register(sender: AnyObject?) {
        guard let userName = userName, let password = password where confirmationMatchesPassword else {
            return
        }

        delegate?.registerViewController(self, didRegisterWithUserName: userName, password: password)
    }

    @IBAction func cancel(sender: AnyObject?) {
        delegate?.registerViewControllerDidCancel(self)
    }

}
