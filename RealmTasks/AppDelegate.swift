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

import RealmSwift
import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        do {

            Realm.setGlobalSynchronizationLoggingLevel(.Verbose)

            //Add Sync credentials to Realm
            var configuration = Realm.Configuration()
            configuration.syncServerURL = NSURL(string:"realm://127.0.0.1:7800/realmtasks")
            configuration.syncUserToken = "ewogICJhY2Nlc3MiIDogWwogICAgInVwbG9hZCIsCiAgICAiZG93bmxvYWQiCiAgXSwKICAiYXBwX2lkIiA6ICJpby5yZWFsbS5FeGFtcGxlIiwKICAiaWRlbnRpdHkiIDogInJlYWxtY2xlYXIiCn0=:qlNQkfAF/qMJK4rQzLqxVuY/n8DYPvDx4GdP52TNbCAhkqC5L4Lp+aK/++lWt8b9SrYh3/4OJtE6AFQi7aHW7RVyl+orj9bksyLZtY+p1fYTQzio1nia420g47322lnRIBsrT4CFoRSd1jHJDcul5nFnLgPjFUFZ1UAXClIv/MyKZeAU3Z+yYnnK+ZnoVuQKmmbrFFfQI6wHC0rgv5/Dvlp0/dkvqsF1hWECRqN+XV7V8vFlCJrxU8V+0Mm+e4B/sQ+IP8ZxZHLa9dSz1EM/gKfeZ8f7v1XWY+d5xPSmSzhoEkz+m5pQg7tvvArbb5emqxn70eZxadQhMu8B734NRQ=="
            Realm.Configuration.defaultConfiguration = configuration


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
        return true
    }
}
