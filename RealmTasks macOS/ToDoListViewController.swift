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
            
            switch changes {
            case .Initial:
                self.tableView.reloadData()
            case .Update(_, let deletions, let insertions, let modifications):
                self.tableView.beginUpdates()
                self.tableView.removeRowsAtIndexes(deletions.toIndexSet(), withAnimation: .EffectFade)
                self.tableView.insertRowsAtIndexes(insertions.toIndexSet(), withAnimation: .EffectFade)
                self.tableView.reloadDataForRowIndexes(modifications.toIndexSet(), columnIndexes: NSIndexSet(index: 0))
                self.tableView.endUpdates()
            case .Error(let error):
                fatalError("\(error)")
            }
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
        
        cell.configureWithToDoItem(items[row])
        
        return cell
    }
    
    func tableView(tableView: NSTableView, didAddRowView rowView: NSTableRowView, forRow row: Int) {
        updateColors()
    }
    
    func tableView(tableView: NSTableView, didRemoveRowView rowView: NSTableRowView, forRow row: Int) {
        updateColors()
    }
    
    private func updateColors() {
        tableView.enumerateAvailableRowViewsUsingBlock { rowView, row in
            rowView.backgroundColor = self.realmColor(forRow: row)
        }
    }
    
    private func realmColor(forRow row: Int) -> NSColor {
        return NSColor.colorForRealmLogoGradient(Double(row) / Double(max(13, tableView.numberOfRows)))
    }
    
}

// MARK: Private Extensions

private extension CollectionType where Generator.Element == Int {
    
    func toIndexSet() -> NSIndexSet {
        let indexSet = NSMutableIndexSet()
        
        forEach { indexSet.addIndex($0) }
        
        return indexSet
    }
    
}
