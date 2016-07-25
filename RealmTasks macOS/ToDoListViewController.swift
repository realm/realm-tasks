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
import RealmSwift

let toDoCellIdentifier = "ToDoItemCell"

class ToDoListViewController: NSViewController {
    
    @IBOutlet var tableView: NSTableView!
    
    private var items = try! Realm().objects(ToDoList).first!.items

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

extension ToDoListViewController: NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return items.count
    }
    
}

extension ToDoListViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeViewWithIdentifier(toDoCellIdentifier, owner: self) as? ToDoItemCellView else {
            fatalError("Unknown cell type")
        }
        
        cell.backgroundColor = realmColor(forRow: row)
        cell.configureWithToDoItem(items[row])
        
        return cell
    }
    
    private func realmColor(forRow row: Int) -> NSColor {
        return NSColor.colorForRealmLogoGradient(Double(row) / Double(max(13, tableView.numberOfRows)))
    }
    
}
