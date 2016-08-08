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

import Cartography
import UIKit
import Realm
import RealmSwift

class ContainerViewController: UIViewController {
    private var titleLabel = UILabel()
    private var titleTopConstraint: NSLayoutConstraint?
    override var title: String? {
        didSet {
            if let title = title {
                titleLabel.text = title
            }
            titleTopConstraint?.constant = (title != nil) ? 20 : 0
            UIView.animateWithDuration(0.2) {
                self.titleLabel.alpha = (self.title != nil) ? 1 : 0
                self.titleLabel.superview?.layoutIfNeeded()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChildVC()
        setupTitleBar()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    private func addChildVC() {
        let firstList = try! Realm().objects(TaskList.self).first!
        let vc = ViewController<Task, TaskList>(
            items: firstList.items,
            colors: UIColor.taskColors(),
            title: firstList.text
        )
        title = firstList.text
        addChildViewController(vc)
        view.addSubview(vc.view)
        vc.didMoveToParentViewController(self)
    }

    private func setupTitleBar() {
        let titleBar = UIToolbar()
        titleBar.barStyle = .BlackTranslucent
        view.addSubview(titleBar)
        constrain(titleBar) { titleBar in
            titleBar.left == titleBar.superview!.left
            titleBar.top == titleBar.superview!.top
            titleBar.right == titleBar.superview!.right
            titleBar.height >= 20
            titleBar.height == 20 ~ UILayoutPriorityDefaultHigh
        }

        titleLabel.font = .boldSystemFontOfSize(13)
        titleLabel.textAlignment = .Center
        titleLabel.textColor = .whiteColor()
        titleBar.addSubview(titleLabel)
        constrain(titleLabel) { titleLabel in
            titleLabel.left == titleLabel.superview!.left
            titleLabel.right == titleLabel.superview!.right
            titleLabel.bottom == titleLabel.superview!.bottom - 5
            titleTopConstraint = (titleLabel.top == titleLabel.superview!.top + 20)
        }
    }
}

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        RLMSyncManager.sharedManager().configureWithAppID(Constants.appID)

        Realm.Configuration.defaultConfiguration = syncRealmConfiguration
        Realm.setGlobalSynchronizationLoggingLevel(.Verbose)

        do {
            let realm = try Realm()
            if realm.isEmpty {
                // Create a default list if none exist
                try realm.write {
                    let list = TaskList()
                    list.initial = true
                    list.text = Constants.defaultListName
                    let listLists = TaskListList()
                    listLists.items.append(list)
                    realm.add(listLists)
                }
            }
        } catch {
            fatalError("Could not open or write to the realm: \(error)")
        }

        window?.rootViewController = ContainerViewController()
        window?.makeKeyAndVisible()

        if let userRealm = try? Realm(configuration: userRealmConfiguration),
            let token = userRealm.objects(User.self).first?.accessToken {
            try! Realm().open(with: token)
        } else {
            logIn()
        }

        return true
    }

    func logIn() {
        let loginManager = RealmSyncLoginManager(authURL: Constants.syncAuthURL, appID: RLMSyncManager.sharedManager().appID ?? "", realmPath: Constants.syncRealmPath)

        loginManager.logIn(fromViewController: window!.rootViewController!) { accessToken, error in
            if let token = accessToken {
                dispatch_async(dispatch_queue_create("io.realm.RealmTasks.bg", nil)) {
                    let userRealm = try! Realm(configuration: userRealmConfiguration)
                    try! userRealm.write {
                        let user = User()
                        user.accessToken = token
                        userRealm.add(user)
                    }
                }
                try! Realm().open(with: token)
                return
            }

            guard let error = error else {
                // This happens when the user chose "Cancel" while logging in, which isn't supported,
                // so just present the login view controller again
                self.logIn()
                return
            }

            // Present error to user

            let alertController = UIAlertController(title: error.localizedDescription, message: error.localizedFailureReason ?? "", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "OK", style: .Default) { _ in
                self.logIn()
            }

            alertController.addAction(defaultAction)
            alertController.preferredAction = defaultAction

            self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}
