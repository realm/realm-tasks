//
//  AppDelegate.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        return true
    }
}
