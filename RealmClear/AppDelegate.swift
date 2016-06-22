//
//  AppDelegate.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import RealmSwift
import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
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
        return true
    }
}
