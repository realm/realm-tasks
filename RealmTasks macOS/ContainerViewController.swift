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
    var constraintGroup = ConstraintGroup()

    @IBAction func showAllLists(sender: AnyObject?) {
        let rootList = try! Realm().objects(TaskListList.self).first!

        presentViewControllerForList(rootList)
    }

    @IBAction func showRecentList(sender: AnyObject?) {
        // TODO: restore from user defaults
        let list = try! Realm().objects(TaskList.self).first!

        presentViewControllerForList(list)
    }

    func presentViewControllerForList<ListType: ListPresentable where ListType: Object>(list: ListType) {
        let listViewController = ListViewController(list: list)

        addChildViewController(listViewController)
        view.addSubview(listViewController.view)

        if let currentListViewController = currentListViewController {
            constrain(listViewController.view, currentListViewController.view, replace: constraintGroup) { newView, oldVIew in
                oldVIew.edges == oldVIew.superview!.edges

                if list is CellPresentable {
                    newView.top == newView.superview!.bottom
                } else {
                    newView.bottom == newView.superview!.top
                }

                newView.height == newView.superview!.height
                newView.width == newView.superview!.width
            }

            view.layoutSubtreeIfNeeded()

            constrain(listViewController.view, currentListViewController.view, replace: constraintGroup) { newView, oldVIew in
                newView.edges == newView.superview!.edges

                if list is CellPresentable {
                    oldVIew.bottom == oldVIew.superview!.top
                } else {
                    oldVIew.top == oldVIew.superview!.bottom
                }

                oldVIew.height == oldVIew.superview!.height
                oldVIew.width == oldVIew.superview!.width
            }

            NSView.animateWithDuration(0.3, animations: {
                NSAnimationContext.currentContext().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) 
                self.view.layoutSubtreeIfNeeded()
            }) {
                currentListViewController.removeFromParentViewController()
                currentListViewController.view.removeFromSuperview()
            }
        } else {
            constrain(listViewController.view, replace: constraintGroup) { view in
                view.edges == view.superview!.edges
            }
        }

        updateToolbarForList(list)

        currentListViewController = listViewController
    }

    private func updateToolbarForList<ListType: ListPresentable where ListType: Object>(list: ListType) {
        guard let toolbar = view.window?.toolbar else {
            return
        }

        if let titleLabel = toolbar.itemWithIdentifier("TitleLabel")?.view as? NSTextField {
            titleLabel.stringValue = (list as? CellPresentable)?.text ?? "Lists"
        }

        if list is CellPresentable {
            if !toolbar.hasItemWithIdentifier("ShowAllListsButton") {
                toolbar.insertItemWithItemIdentifier("ShowAllListsButton", atIndex: toolbar.items.count - 1)
            }
        } else if let index = toolbar.indexOfItemWithIdentifier("ShowAllListsButton") {
            view.window?.toolbar?.removeItemAtIndex(index)
        }

        // Let the new controller takes care about toolbar validation
        view.window?.makeFirstResponder(childViewControllers.first)
    }

}

private extension NSToolbar {

    func hasItemWithIdentifier(identifier: String) -> Bool {
        return itemWithIdentifier(identifier) != nil
    }

    func itemWithIdentifier(identifier: String) -> NSToolbarItem? {
        guard let index = indexOfItemWithIdentifier(identifier) else {
            return nil
        }

        return items[index]
    }

    func indexOfItemWithIdentifier(identifier: String) -> Int? {
        for (index, item) in items.enumerate() {
            if item.itemIdentifier == identifier {
                return index
            }
        }

        return nil
    }

}
