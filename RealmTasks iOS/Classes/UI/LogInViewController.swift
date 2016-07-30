//
//  LogInViewController.swift
//  RealmSyncAuth
//
//  Created by Dmitry Obukhov on 27/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import UIKit

enum LogInViewControllerReturnCode: Int {
    case LogIn
    case Register
    case Cancel
}

class LogInViewController: UIViewController {

    @IBOutlet private weak var userNameTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var logInButton: UIButton!

    var completionHandler: ((userName: String?, password: String?, returnCode: LogInViewControllerReturnCode) -> ())?

    override func viewDidLoad() {
        userNameTextField.addTarget(self, action: #selector(updateUI), forControlEvents: .EditingChanged)
        passwordTextField.addTarget(self, action: #selector(updateUI), forControlEvents: .EditingChanged)

        updateUI()
    }

    @IBAction func logIn(sender: AnyObject?) {
        guard userInputValid() else {
            return
        }

        dismissViewControllerAnimated(true) {
            self.completionHandler?(userName: self.userNameTextField.text, password: self.passwordTextField.text, returnCode: .LogIn)
        }
    }

    @IBAction func cancel(sender: AnyObject?) {
        dismissViewControllerAnimated(true) {
            self.completionHandler?(userName: nil, password: nil, returnCode: .Cancel)
        }
    }

    private dynamic func updateUI() {
        logInButton.enabled = userInputValid()
    }

    private func userInputValid() -> Bool {
        guard
            let userName = userNameTextField.text where userName.characters.count > 0,
            let password = passwordTextField.text where password.characters.count > 0
        else {
            return false
        }

        return true
    }

}

extension LogInViewController {

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let viewController = segue.destinationViewController as? RegisterViewController {
            viewController.completionHandler = { userName, password, returnCode in
                if returnCode == .Register {
                    self.dismissViewControllerAnimated(true) {
                        self.completionHandler?(userName: userName, password: password, returnCode: .Register)
                    }
                }
            }
        }
    }

}

extension LogInViewController: UITextFieldDelegate {

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == userNameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            logIn(nil)
        }

        return false
    }

}

extension LogInViewController: UINavigationBarDelegate {

    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }

}
