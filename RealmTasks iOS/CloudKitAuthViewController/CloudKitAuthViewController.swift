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
import CloudKit

class CloudKitAuthViewController: UIViewController {

    @IBOutlet weak var reloadButton: UIButton?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var settingsButton: UIButton?
    
    var completionHandler: ((accessToken: String?, error: NSError?) -> ())?
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        beginAuthentication()
    }
    
    func beginAuthentication() {
        activityIndicator?.startAnimating()
        reloadButton?.hidden = true
        statusLabel?.hidden = true
        settingsButton?.enabled = false
        
        downloadCloudKitUserRecord()
    }
    
    func downloadCloudKitUserRecord() {
        let container = CKContainer.defaultContainer()
        container.fetchUserRecordIDWithCompletionHandler({ (recordID: CKRecordID?, error: NSError?) in
            if let error = error {
                self.showError(error.localizedDescription)
                return
            }
          
            let userAccessToken = recordID?.recordName
            self.completionHandler?(accessToken: userAccessToken, error: error)
        })
    }
    
    func showError(message: String) {
        NSOperationQueue.mainQueue().addOperationWithBlock { 
            self.activityIndicator?.stopAnimating()
            self.settingsButton?.enabled = true
            self.reloadButton?.hidden = false
            self.statusLabel?.hidden = false
            self.statusLabel?.text = message
        }
    }
    
    //MARK: Button Callbacks
    @IBAction func reloadButtonTapped(sender: AnyObject?) {
        beginAuthentication()
    }
    
    @IBAction func cloudKitButtonTapped(sender: AnyObject?) {
        let url = NSURL(string: "prefs:root=CASTLE")
        UIApplication.sharedApplication().openURL(url!)
    }
}
