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
import RealmSwift

// MARK: Models

final class TaskListList: Object {
    let items = List<TaskList>()
    dynamic var id = 0

    override static func primaryKey() -> String? {
        return "id"
    }
}

final class TaskList: Object {
    dynamic var text = ""
    dynamic var completed = false
    dynamic var id = ""
    let items = List<Task>()

    override static func primaryKey() -> String? {
        return "id"
    }
}

final class Task: Object {
    dynamic var text = ""
    dynamic var completed = false
}

// MARK: View Controller

class ViewController: UITableViewController {
    var items = List<Task>()
    var notificationToken: NotificationToken!
    var realm: Realm!

    // MARK: Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRealm()
    }

    func setupUI() {
        title = "My Tasks"
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationItem.leftBarButtonItem = editButtonItem()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(add))
    }

    func setupRealm() {
        // Log in existing user with username and password
        let username = "test"
        let password = "test"
        User.authenticateWithCredential(.UsernamePassword(username: username, password: password), actions: [],
                                        authServerURL: NSURL(string: "http://127.0.0.1:8080")!) { user, error in
            guard let user = user else {
                fatalError(String(error))
            }
            // Open Realm
            let configuration = Realm.Configuration(
                syncConfiguration: (user, NSURL(string: "realm://127.0.0.1/~/realmtasks")!)
            )
            self.realm = try! Realm(configuration: configuration)
            func updateList() {
                if self.items.realm == nil, let list = self.realm.objects(TaskList.self).first {
                    self.items = list.items
                }
                self.tableView.reloadData()
            }
            updateList()

            // Notify us when Realm changes
            self.notificationToken = self.realm.addNotificationBlock { _ in
                updateList()
            }
        }
    }

    deinit {
        notificationToken.stop()
    }

    // MARK: UITableView

    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.text
        cell.textLabel?.alpha = item.completed ? 0.5 : 1
        return cell
    }

    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        try! items.realm?.write {
            items.move(from: fromIndexPath.row, to: toIndexPath.row)
        }
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            try! items.realm?.write {
                items.removeAtIndex(indexPath.row)
            }
        }
    }

    // MARK: Functions

    func add() {
        let alertController = UIAlertController(title: "New Task", message: "Enter Task Name", preferredStyle: .Alert)
        var alertTextField: UITextField!
        alertController.addTextFieldWithConfigurationHandler { textField in
            alertTextField = textField
            textField.placeholder = "Task Name"
        }
        alertController.addAction(UIAlertAction(title: "Add", style: .Default) { _ in
            guard let text = alertTextField.text where !text.isEmpty else { return }
            let items = self.items
            try! items.realm?.write {
                items.append(Task(value: ["text": text]))
            }
        })
        presentViewController(alertController, animated: true, completion: nil)
    }
}
