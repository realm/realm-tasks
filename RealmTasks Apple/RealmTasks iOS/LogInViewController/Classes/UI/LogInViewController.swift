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

enum LogInViewControllerReturnCode: Int {
    case logIn
    case register
    case cancel
}

class LogInViewController: UIViewController {

    @IBOutlet fileprivate weak var userNameTextField: UITextField!
    @IBOutlet fileprivate weak var passwordTextField: UITextField!
    @IBOutlet fileprivate weak var logInButton: UIButton!

    struct LogInResponse {
        let username: String?
        let password: String?
        let returnCode: LogInViewControllerReturnCode
    }

    var completionHandler: ((LogInResponse) -> Void)?

    override func viewDidLoad() {
        userNameTextField.addTarget(self, action: #selector(updateUI), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(updateUI), for: .editingChanged)

        updateUI()
    }

    @IBAction func logIn(_ sender: AnyObject?) {
        guard userInputValid() else {
            return
        }

        dismiss(animated: true) {
            self.completionHandler?(LogInResponse(username: self.userNameTextField.text,
                                                  password: self.passwordTextField.text,
                                                  returnCode: .logIn))
        }
    }

    private dynamic func updateUI() {
        logInButton.isEnabled = userInputValid()
    }

    private func userInputValid() -> Bool {
        guard
            let userName = userNameTextField.text, !userName.isEmpty,
            let password = passwordTextField.text, !password.isEmpty
        else {
            return false
        }

        return true
    }

}

extension LogInViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? RegisterViewController {
            viewController.initialUserName = userNameTextField.text
            viewController.completionHandler = { response in
                if response.returnCode == .register {
                    self.dismiss(animated: true) {
                        self.completionHandler?(LogInResponse(username: response.username,
                                                              password: response.password,
                                                              returnCode: .register))
                    }
                }
            }
        }
    }

}

extension LogInViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userNameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            logIn(nil)
        }

        return false
    }

}

extension LogInViewController: UINavigationBarDelegate {

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }

}
