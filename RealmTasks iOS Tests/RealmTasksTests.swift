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

import XCTest
import Realm
import RealmSwift
@testable import Realm_Tasks

class RealmTasksTests: XCTestCase {

    lazy var realm = try! Realm()
    var vc: ViewController<Task, TaskList>!
    let window = UIWindow()

    override func setUp() {
        super.setUp()

        let config = RLMRealmConfiguration()
        config.inMemoryIdentifier = "test"
        RLMRealmConfiguration.setDefaultConfiguration(config)

        if realm.isEmpty {
            try! realm.write {
                let list = TaskList()
                list.initial = true
                list.text = Constants.defaultListName
                let listLists = TaskListList()
                listLists.items.append(list)
                realm.add(listLists)
            }
        }

        let taskList = realm.objects(TaskList.self).first!

        vc = ViewController(parent: taskList, colors: UIColor.taskColors())
        window.rootViewController = vc
        window.makeKeyAndVisible()

        _ = vc.view
        vc.tableView.layoutIfNeeded()
    }

    override func tearDown() {
        super.tearDown()
        let taskList = realm.objects(TaskList.self).first!
        try! realm.write {
            taskList.items.removeAll()
        }
        vc.tableView.reloadData()
    }

    func testInitialData() {
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 0)
    }

    func testAddNewItem() {
        addNewItem()
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 1)
    }

    func testAddNewItemFromSyncWhileEditing() {
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 0)

        addNewItem()
        setTextToEditingCell("item 1")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 1)

        addNewItem()
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 2)

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let realm = try! Realm()
            let items = realm.objects(TaskList.self).first!.items
            try! realm.write {
                items.insert(Task(), atIndex: 0)
            }
        }
        wait()

        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 1)
    }

    func testDeleteItem() {
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 0)

        addNewItem()
        setTextToEditingCell("item 1")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 1)

        addNewItem()
        setTextToEditingCell("item 2")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 2)

        addNewItem()
        setTextToEditingCell("item 3")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 3)

        deleteItemAt(NSIndexPath(forRow: 0, inSection: 0))
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 2)

        deleteItemAt(NSIndexPath(forRow: 1, inSection: 0))
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 1)
    }

    func testDeleteItemFromSync() {
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 0)

        addNewItem()
        setTextToEditingCell("item 1")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 1)

        addNewItem()
        setTextToEditingCell("item 2")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 2)

        addNewItem()
        setTextToEditingCell("item 2")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 3)

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let realm = try! Realm()
            let items = realm.objects(TaskList.self).first!.items
            try! realm.write {
                items.removeLast()
            }
        }
        wait()

        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 2)
    }

    func testDeleteItemFromSyncWhileEditing() {
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 0)

        addNewItem()
        setTextToEditingCell("item 1")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 1)

        addNewItem()
        setTextToEditingCell("item 2")
        wait()
        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 2)

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let realm = try! Realm()
            let items = realm.objects(TaskList.self).first!.items
            try! realm.write {
                items.removeLast()
            }
        }
        wait()

        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 1)
    }

    // Emulate task list operations

    private func addNewItem() {
        vc.tableView.contentOffset.y = -114.0
        vc.scrollViewDidEndDragging(vc.tableView, willDecelerate: true)
    }

    private func deleteItemAt(indexPath: NSIndexPath) {
        let cell = vc.tableView.cellForRowAtIndexPath(indexPath) as! TableViewCell<Task>
        cell.itemDeleted?(cell.item)
    }

    private func completeItemAt(indexPath: NSIndexPath) {
        let cell = vc.tableView.cellForRowAtIndexPath(indexPath) as! TableViewCell<Task>
        cell.itemDeleted?(cell.item)
    }

    private func setTextToEditingCell(text: String) {
        let textView = vc.view.currentFirstResponder as! UITextView
        textView.text = text
    }

    private func endEditing() {
        vc.view.endEditing(true)
    }

    private func wait(secs: NSTimeInterval = 0.1) {
        NSRunLoop.mainRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: secs))
    }

}

extension UIView {
    var currentFirstResponder: UIResponder? {
        if self.isFirstResponder() {
            return self
        }
        for view in self.subviews {
            if let responder = view.currentFirstResponder {
                return responder
            }
        }
        return nil
    }
}
