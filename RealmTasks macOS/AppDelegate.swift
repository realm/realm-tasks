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
import Realm
import RealmSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private(set) var mainWindowController: NSWindowController!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        RLMSyncManager.sharedManager().configureWithAppID(Constants.appID)
        
        Realm.Configuration.defaultConfiguration = syncRealmConfiguration
        Realm.setGlobalSynchronizationLoggingLevel(.Verbose)
        
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
        
        mainWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateControllerWithIdentifier("MainWindowController") as! NSWindowController
        mainWindowController.showWindow(nil)
        
        if let userRealm = try? Realm(configuration: userRealmConfiguration),
            let token = userRealm.objects(User.self).first?.accessToken {
            try! Realm().open(with: token)
        } else {
            // TODO: log in
        }
    }
    
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindowController.showWindow(nil)
        
        return true
    }

}
