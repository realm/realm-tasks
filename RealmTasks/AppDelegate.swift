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
import Realm
import RealmSwift
import RealmSyncAuth

#if DEBUG
let syncHost = localIPAddress
#else
let syncHost = "SPECIFY_PRODUCTION_HOST_HERE"
#endif

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)
    
    let syncAuthURL = NSURL(string: "http://\(syncHost):3000/auth")!
    let syncServerURL = NSURL(string: "realm://\(syncHost):7800/private/realmtasks")!
    
    let appID = NSBundle.mainBundle().bundleIdentifier!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        RLMSyncManager.sharedManager().configureWithAppID(appID)
        
        Realm.setGlobalSynchronizationLoggingLevel(.Verbose)
        
        //Add Sync credentials to Realm
        var configuration = Realm.Configuration()
        configuration.syncServerURL = syncServerURL
        Realm.Configuration.defaultConfiguration = configuration
        
        do {
            let realm = try Realm()
            if realm.isEmpty {
                // Create a default list if none exist
                try realm.write {
                    realm.add(ToDoList())
                }
            }
        } catch {
            fatalError("Could not open or write to the realm: \(error)")
        }
        
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        
        logIn()
        
        return true
    }
    
    func logIn() {
        let logInManager = RealmSyncLoginManager(authURL: syncAuthURL, appID: appID, realmPath: "realmtasks")
        
        logInManager.logIn(fromViewController: window!.rootViewController!) { accessToken, error in
            if let token = accessToken {
                try! Realm().open(with: token)
            } else {
                if let error = error {
                    let alertController = UIAlertController(title: error.localizedDescription, message: error.localizedFailureReason ?? "", preferredStyle: .Alert)
                    let defaultAction = UIAlertAction(title: "I see..", style: .Default, handler: { _ in
                        // Try ligin again in case of error
                        self.logIn()
                    })
                    
                    alertController.addAction(defaultAction)
                    alertController.preferredAction = defaultAction
                    
                    self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
                } else {
                    // This happens whe user choose "Cancel" while login, this is not supported currently, so just show Login view angain
                    self.logIn()
                }
            }
        }
    }

}
