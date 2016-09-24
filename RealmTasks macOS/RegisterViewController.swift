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
