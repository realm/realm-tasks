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

import Foundation
import RealmSwift
import UIKit

private var titleKVOContext = 0

class ListPresenter<Item: Object, Parent: Object where Item: CellPresentable, Parent: ListPresentable, Parent.Item == Item>: NSObject {

    var cellPresenter: CellPresenter<Item>!
    var tablePresenter: TablePresenter<Parent>!

    var viewController: ViewControllerProtocol! {
        didSet {
            cellPresenter.viewController = viewController
            tablePresenter.viewController = viewController

            if viewController != nil {
                observeListTitle()
            } else if observingText {
                parent.removeObserver(self, forKeyPath: "text")
            }

            setupNotifications()
        }
    }

    let parent: Parent
    init(parent: Parent, colors: [UIColor]) {
        self.parent = parent
        cellPresenter = CellPresenter(items: parent.items)
        tablePresenter = TablePresenter(parent: parent, colors: colors)
        tablePresenter.cellPresenter = cellPresenter
    }

    deinit {
        notificationToken?.stop()
    }

    // MARK: List title
    private var observingText = false

    private func observeListTitle() {
        if let parent = parent as? CellPresentable {
            (parent as! Object).addObserver(self, forKeyPath: "text", options: .New, context: &titleKVOContext)
            viewController.setListTitle(parent.text)
            observingText = true
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &titleKVOContext {
            viewController.setListTitle((parent as! CellPresentable).text)
        }
    }

    // MARK: Notifications
    private var notificationToken: NotificationToken?

    private func setupNotifications() {
        // TODO: Remove filter once https://github.com/realm/realm-cocoa-private/issues/226 is fixed
        notificationToken = parent.items.filter("TRUEPREDICATE").addNotificationBlock { [unowned self] changes in
            // Do not perform an update if the user is editing a cell at this moment
            // (The table will be reloaded by the 'end editing' call of the active cell)
            guard self.cellPresenter.currentlyEditingCell == nil else {
                return
            }

            self.viewController.tableView.reloadData()
        }
    }
}
