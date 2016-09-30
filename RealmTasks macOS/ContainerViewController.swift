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

import Cocoa
import RealmSwift
import Cartography

class ContainerViewController: NSViewController {

    var currentListViewController: NSViewController?
    var constraintGroup = ConstraintGroup()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let visualEffectView = view as? NSVisualEffectView {
            if #available(OSX 10.11, *) {
                visualEffectView.material = .UltraDark
            } else {
                visualEffectView.material = .Dark
            }

            visualEffectView.state = .Active
        }
    }

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

        currentListViewController = listViewController

        updateToolbarForList(list)
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
        view.window?.makeFirstResponder(currentListViewController)
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
