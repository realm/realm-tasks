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

import UIKit
import FBSDKLoginKit

enum LogInViewControllerReturnCode: Int {
    case LogIn
    case Register
    case FacebookLogIn
    case Cancel
}

class LogInViewController: UIViewController {

    @IBOutlet private weak var userNameTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var logInButton: UIButton!
    @IBOutlet weak var facebookLogInButton: FBSDKLoginButton!

    var completionHandler: ((userName: String?, password: String?, facebookAccessToken: String?, returnCode: LogInViewControllerReturnCode) -> ())?

    override func viewDidLoad() {
        userNameTextField.addTarget(self, action: #selector(updateUI), forControlEvents: .EditingChanged)
        passwordTextField.addTarget(self, action: #selector(updateUI), forControlEvents: .EditingChanged)

        facebookLogInButton.delegate = self
        
        updateUI()
    }

    @IBAction func logIn(sender: AnyObject?) {
        guard userInputValid() else {
            return
        }

        dismissViewControllerAnimated(true) { 
            self.completionHandler?(userName: self.userNameTextField.text, password: self.passwordTextField.text, facebookAccessToken: nil, returnCode: .LogIn)
        }
    }

    @IBAction func cancel(sender: AnyObject?) {
        dismissViewControllerAnimated(true) {
            self.completionHandler?(userName: nil, password: nil, facebookAccessToken: nil, returnCode: .Cancel)
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
                        self.completionHandler?(userName: userName, password: password, facebookAccessToken: nil, returnCode: .Register)
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

extension LogInViewController: FBSDKLoginButtonDelegate {

    func loginButtonWillLogin(loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if let _ = error {
            return
        }
        if result.isCancelled {
            return
        }
        dismissViewControllerAnimated(true) {
            self.completionHandler?(userName: nil, password: nil, facebookAccessToken: result.token.tokenString, returnCode: .FacebookLogIn)
        }
    }

    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {}

}
