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

import Cartography
import Cocoa
import RealmSwift

fileprivate let toolbarTitleViewIdentifier = "TitleView"
fileprivate let toolbarShowAllListsButtonIdentifier = "ShowAllListsButton"

class ContainerViewController: NSViewController {

    private(set) var currentListViewController: NSViewController?
    private var constraintGroup = ConstraintGroup()
    private var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let visualEffectView = view as? NSVisualEffectView {
            if #available(OSX 10.11, *) {
                visualEffectView.material = .ultraDark
            } else {
                visualEffectView.material = .dark
            }

            visualEffectView.state = .active
        }
    }

    @IBAction func showAllLists(sender: AnyObject?) {
        let rootList: TaskListList = try! Realm().objects(TaskListList.self).first!
        presentViewControllerForList(list: rootList)
    }

    @IBAction func showRecentList(sender: AnyObject?) {
        // TODO: restore from user defaults
        let list = try! Realm().objects(TaskList.self).first!
        presentViewControllerForList(list: list)
    }

    func presentViewControllerForList<ListType: ListPresentable>(list: ListType) where ListType: Object {
        let listViewController = ListViewController(list: list)

        addChildViewController(listViewController)
        view.addSubview(listViewController.view)

        if let currentListViewController = currentListViewController {
            constrain(listViewController.view, currentListViewController.view, replace: constraintGroup) { newView, oldView in
                oldView.edges == oldView.superview!.edges

                if list is CellPresentable {
                    newView.top == newView.superview!.bottom
                } else {
                    newView.bottom == newView.superview!.top
                }

                newView.left == newView.superview!.left
                newView.size == newView.superview!.size
            }

            view.layoutSubtreeIfNeeded()

            constrain(listViewController.view, currentListViewController.view, replace: constraintGroup) { newView, oldView in
                newView.edges == newView.superview!.edges

                if list is CellPresentable {
                    oldView.bottom == oldView.superview!.top
                } else {
                    oldView.top == oldView.superview!.bottom
                }

                oldView.left == oldView.superview!.left
                oldView.size == oldView.superview!.size
            }

            listViewController.view.alphaValue = 0

            NSView.animate(duration: 0.3, animations: {
                currentListViewController.view.alphaValue = 0
                listViewController.view.alphaValue = 1

                view.layoutSubtreeIfNeeded()
            }) {
                currentListViewController.removeFromParentViewController()
                currentListViewController.view.removeFromSuperview()
            }
        } else {
            constrain(listViewController.view, replace: constraintGroup) { view in
                view.edges == view.superview!.edges
            }
        }

        currentListViewController = listViewController

        updateToolbarForList(list: list)

        notificationToken?.stop()
        notificationToken = list.realm?.addNotificationBlock { [unowned self] _, _ in
            // Show all lists if list is deleted on other device
            if (list as Object).isInvalidated {
                self.showAllLists(sender: nil)
            }
        }
    }

    private func updateToolbarForList<ListType: ListPresentable>(list: ListType) where ListType: Object {
        guard let toolbar = view.window?.toolbar else {
            return
        }

        if let titleView = toolbar.itemWithIdentifier(identifier: toolbarTitleViewIdentifier)?.view as? TitleView {
            titleView.text = (list as? CellPresentable)?.text ?? "Lists"
        }

        if list is CellPresentable {
            if !toolbar.hasItemWithIdentifier(identifier: toolbarShowAllListsButtonIdentifier) {
                toolbar.insertItem(withItemIdentifier: toolbarShowAllListsButtonIdentifier, at: toolbar.items.count - 1)
            }
        } else if let index = toolbar.indexOfItemWithIdentifier(identifier: toolbarShowAllListsButtonIdentifier) {
            view.window?.toolbar?.removeItem(at: index)
        }

        // Let the new controller takes care about toolbar validation
        view.window?.makeFirstResponder(currentListViewController)
    }

}

private extension NSToolbar {

    func hasItemWithIdentifier(identifier: String) -> Bool {
        return itemWithIdentifier(identifier: identifier) != nil
    }

    func itemWithIdentifier(identifier: String) -> NSToolbarItem? {
        guard let index = indexOfItemWithIdentifier(identifier: identifier) else {
            return nil
        }

        return items[index]
    }

    func indexOfItemWithIdentifier(identifier: String) -> Int? {
        for (index, item) in items.enumerated() {
            if item.itemIdentifier == identifier {
                return index
            }
        }

        return nil
    }

}
