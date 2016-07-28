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
    private var disableNotificationsState = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotifications()
    }
    
    private func setupNotifications() {
        notificationToken = items.addNotificationBlock { changes in
            if self.disableNotificationsState {
                return
            }
            
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
    
    private func temporarilyDisableNotifications(reloadTable reloadTable: Bool = true) {
        disableNotificationsState = true
        delay(0.6) {
            self.disableNotificationsState = false
            
            if reloadTable {
                self.tableView.reloadData()
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
        let cellView: ToDoItemCellView
        
        if let view = tableView.makeViewWithIdentifier(toDoCellIdentifier, owner: self) as? ToDoItemCellView {
            cellView = view
        } else {
            cellView = ToDoItemCellView(identifier: toDoCellIdentifier)
        }
        
        cellView.configureWithToDoItem(items[row])
        cellView.backgroundColor = self.realmColor(forRow: row)
        cellView.delegate = self
        
        return cellView
    }
    
    func tableView(tableView: NSTableView, didAddRowView rowView: NSTableRowView, forRow row: Int) {
        updateColors()
    }
    
    func tableView(tableView: NSTableView, didRemoveRowView rowView: NSTableRowView, forRow row: Int) {
        updateColors()
    }
    
    private func updateColors() {
        tableView.enumerateAvailableRowViewsUsingBlock { _, row in
            if let cellView = self.tableView.viewAtColumn(0, row: row, makeIfNecessary: false) as? ToDoItemCellView {
                NSView.animateWithDuration(5.0, animations: { 
                    cellView.backgroundColor = self.realmColor(forRow: row)
                })
            }
        }
    }
    
    private func realmColor(forRow row: Int) -> NSColor {
        return NSColor.colorForRealmLogoGradient(Double(row) / Double(max(13, tableView.numberOfRows)))
    }
    
}

extension ToDoListViewController: ToDoItemCellViewDelegate {
    
    func cellView(view: ToDoItemCellView, didComplete complete: Bool) {
        guard let (item, index) = findItemForCellView(view) else {
            return
        }
        
        let destinationIndex: Int
        
        if complete {
            // move cell to bottom
            destinationIndex = items.count - 1
        } else {
            // move cell just above the first completed item
            let completedCount = items.filter("completed = true").count
            destinationIndex = items.count - completedCount
        }
        
        delay(0.2) {
            self.temporarilyDisableNotifications()
            
            try! item.realm?.write {
                item.completed = complete
                
                if (index != destinationIndex) {
                    self.items.removeAtIndex(index)
                    self.items.insert(item, atIndex: destinationIndex)
                }
            }
            
            self.tableView.moveRowAtIndex(index, toIndex: destinationIndex)
        }
    }
    
    func cellViewDidDelete(view: ToDoItemCellView) {
        guard let (item, index) = findItemForCellView(view) else {
            return
        }
        
        temporarilyDisableNotifications(reloadTable: false)
        
        try! item.realm?.write {
            items.realm?.delete(item)
        }
        
        tableView.removeRowsAtIndexes(NSIndexSet(index: index), withAnimation: .SlideLeft)
    }
    
    func cellViewDidBeginEditing(view: ToDoItemCellView) {
        
    }
    
    func cellViewDidChangeText(view: ToDoItemCellView) {
        
    }
    
    func cellViewDidEndEditing(view: ToDoItemCellView) {
        guard let (item, _) = findItemForCellView(view) else {
            return
        }
        
        temporarilyDisableNotifications(reloadTable: false)
        
        try! item.realm?.write {
            item.text = view.text
        }
    }
    
    private func findItemForCellView(view: NSView) -> (item: ToDoItem, index: Int)? {
        let index = tableView.rowForView(view)
        
        if index < 0 {
            return nil
        }
        
        return (items[index], index)
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

// MARK: Private Functions

private func delay(time: Double, block: () -> ()) {
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue(), block)
}
