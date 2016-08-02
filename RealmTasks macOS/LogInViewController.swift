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

protocol LogInViewControllerDelegate: class {
    
    func logInViewController(viewController: LogInViewController, logInWithUserName userName: String, password: String)
    func logInViewController(viewController: LogInViewController, registerWithUserName userName: String, password: String)
    
}

class LogInViewController: NSViewController {
    
    weak var delelegate: LogInViewControllerDelegate?
    
    var userName: String?
    var password: String?
    
    @IBAction func logIn(sender: AnyObject?) {
        guard let userName = userName, let password = password else {
            return
        }

        delelegate?.logInViewController(self, logInWithUserName: userName, password: password)
    }
    
    @IBAction func register(sender: AnyObject?) {
        guard let userName = userName, let password = password else {
            return
        }
        
        delelegate?.logInViewController(self, registerWithUserName: userName, password: password)
    }
    
}
