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
import Cartography

class ContainerViewController: NSViewController {

    var currentListViewController: NSViewController?

    func presentViewControllerForList<ListType: ListPresentable where ListType: Object>(list: ListType) {
        let listViewController = ListViewController(list: list)

        currentListViewController = listViewController
        view.addSubview(listViewController.view)

        constrain(listViewController.view) { view in
            view.edges == view.superview!.edges
        }

        view.window?.title = (list as? CellPresentable)?.text ?? "Lists"
    }

}
