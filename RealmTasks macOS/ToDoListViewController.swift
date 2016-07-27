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
    private var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotifications()
    }
    
    private func setupNotifications() {
        notificationToken = items.addNotificationBlock { changes in
            // FIXME: Hack to work around sync possibly pulling in a new list.
            // Ideally we'd use ToDoList with primary keys, but those aren't currently supported by sync.
            let realm = self.items.realm!
            let lists = realm.objects(ToDoList)
            let hasMultipleLists = lists.count > 1
            
            if hasMultipleLists {
                self.items = lists.first!.items
                
                defer {
                    // Append all other items while deleting their lists, in case they were created locally before sync
                    try! realm.write {
                        while lists.count > 1 {
                            self.items.appendContentsOf(lists.last!.items)
                            realm.delete(lists.last!)
                        }
                    }
                    
                    // Resubscribe to notifications
                    self.setupNotifications()
                }
            }
            
            // TODO: add fancy animations
            self.tableView.reloadData()
        }
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
        
        cell.configureWithToDoItem(items[row], color: realmColor(forRow: row))
        
        return cell
    }
    
    private func realmColor(forRow row: Int) -> NSColor {
        return .colorForRealmLogoGradient(Double(row) / Double(max(13, tableView.numberOfRows)))
    }
    
}
