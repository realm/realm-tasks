////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016-2017 Realm Inc.
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
@testable import RealmTasks

class RealmTasksTests: XCTestCase {

    lazy var realm = try! Realm()
    var vc: ViewController<Task, TaskList>! // swiftlint:disable:this variable_name
    let window = UIWindow()

    override func setUp() {
        super.setUp()

        let config = RLMRealmConfiguration()
        config.inMemoryIdentifier = "test"
        RLMRealmConfiguration.setDefault(config)

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
        if realm.isInWriteTransaction {
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
        // Need to allow the notification to propagate, so advance the runloop.
        wait()
        vc.tableView.reloadData()
    }

    func testInitialData() {
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 0)
    }

    func testAddNewItem() {
        addNewItem()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 1)
    }

    func testAddNewItemFromSyncWhileEditing() {
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 0)

        addNewItem()
        setTextToEditingCell(text: "item 1")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 1)

        addNewItem()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 2)
    }

    func testDeleteItem() {
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 0)

        addNewItem()
        setTextToEditingCell(text: "item 1")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 1)

        addNewItem()
        setTextToEditingCell(text: "item 2")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 2)

        addNewItem()
        setTextToEditingCell(text: "item 3")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 3)

        deleteItemAt(indexPath: NSIndexPath(row: 0, section: 0))
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 2)

        deleteItemAt(indexPath: NSIndexPath(row: 1, section: 0))
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 1)
    }

    func testDeleteItemFromSync() {
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 0)

        addNewItem()
        setTextToEditingCell(text: "item 1")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 1)

        addNewItem()
        setTextToEditingCell(text: "item 2")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 2)

        addNewItem()
        setTextToEditingCell(text: "item 2")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 3)

        deleteItemFromSync()
        wait()

        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 2)
    }

    func testDeleteItemFromSyncWhileEditing() {
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 0)

        addNewItem()
        setTextToEditingCell(text: "item 1")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 1)

        addNewItem()
        setTextToEditingCell(text: "item 2")
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 2)
    }

    func testCompleteAndDeleteFromSync() {
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 0)

        addNewItem()
        setTextToEditingCell(text: "item 1")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 1)

        addNewItem()
        setTextToEditingCell(text: "item 2")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 2)

        addNewItem()
        setTextToEditingCell(text: "item 3")
        wait()
        endEditing()
        wait()
        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 3)

        deleteItemFromSync()
        completeItemAt(indexPath: NSIndexPath(row: 2, section: 0))
        wait()

        XCTAssertEqual(vc.tableView.dataSource!.tableView(vc.tableView, numberOfRowsInSection: 0), 2)
    }

    // Emulate task list operations

    private func addNewItem() {
        vc.tableView.contentOffset.y = -114.0
        vc.scrollViewDidEndDragging(vc.tableView, willDecelerate: true)
    }

    private func deleteItemAt(indexPath: NSIndexPath) {
        let cell = vc.tableView.cellForRow(at: indexPath as IndexPath) as! TableViewCell<Task>
        cell.presenter.delete(item: cell.item)
    }

    private func completeItemAt(indexPath: NSIndexPath) {
        let cell = vc.tableView.cellForRow(at: indexPath as IndexPath) as! TableViewCell<Task>
        cell.setCompleted(true)
    }

    private func setTextToEditingCell(text: String) {
        let textView = vc.view.currentFirstResponder as! UITextView
        textView.text = text
    }

    private func endEditing() {
        vc.view.endEditing(true)
    }

    private func wait(secs: TimeInterval = 0.1) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: secs))
    }

    // Emulate notifications from sync

    private func insertItemFromSync(index: Int = 0) {
        DispatchQueue.global(qos: .background).async {
            let realm = try! Realm()
            let items = realm.objects(TaskList.self).first!.items
            try! realm.write {
                items.insert(Task(), at: index)
            }
        }
    }

    private func deleteItemFromSync() {
        DispatchQueue.global(qos: .background).async {
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
        if self.isFirstResponder {
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
