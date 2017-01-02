////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import XCTest
import Realm
import RealmSwift
@testable import Realm_Tasks

class RealmTasksTests: XCTestCase {

    lazy var realm = try! Realm()
    var vc: ViewController<Task, TaskList>! // swiftlint:disable:this variable_name
    let window = UIWindow()

    override func setUp() {
        super.setUp()

        let config = RLMRealmConfiguration()
        config.inMemoryIdentifier = "test"
        RLMRealmConfiguration.setDefaultConfiguration(config)

        if realm.isEmpty {
            try! realm.write {
                let list = TaskList()
                list.id = ""
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
        if realm.inWriteTransaction {
            realm.cancelWrite()
        }

        if let textView = vc.view.currentFirstResponder as? UITextView {
            textView.delegate = nil
            endEditing()
        }

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

        insertItemFromSync()
        wait()

        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 3)
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

        deleteItemFromSync()
        wait()

        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 2)
    }

    // Failing Test
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

        deleteItemFromSync()
        wait()

        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 1)
    }

    // Failing Test
    func testCompleteAndDeleteFromSync() {
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

        deleteItemFromSync()
        completeItemAt(NSIndexPath(forRow: 2, inSection: 0))
        wait()

        XCTAssertEqual(vc.tableView(vc.tableView, numberOfRowsInSection: 0), 2)
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
        cell.itemCompleted?(cell.item)
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

    // Emulate notifications from sync

    private func insertItemFromSync(index: Int = 0) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let realm = try! Realm()
            let items = realm.objects(TaskList.self).first!.items
            try! realm.write {
                items.insert(Task(), atIndex: index)
            }
        }
    }

    private func deleteItemFromSync() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let realm = try! Realm()
            let items = realm.objects(TaskList.self).first!.items
            try! realm.write {
                items.removeLast()
            }
        }
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
