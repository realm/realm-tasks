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

    @IBAction func showAllLists(_ sender: AnyObject?) {
        let rootList = try! Realm().objects(TaskListList.self).first!
        presentViewController(for: rootList)
    }

    @IBAction func showRecentList(_ sender: AnyObject?) {
        // TODO: restore from user defaults
        let list = try! Realm().objects(TaskList.self).first!
        presentViewController(for: list)
    }

    func presentViewController<ListType: ListPresentable>(for list: ListType) where ListType: Object {
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

        updateToolbar(for: list)

        notificationToken?.invalidate()
        notificationToken = list.realm?.observe { [unowned self] _, _ in
            // Show all lists if list is deleted on other device
            if list.isInvalidated {
                self.showAllLists(nil)
            }
        }
    }

    func dismissAllViewControllers() {
        currentListViewController?.removeFromParentViewController()
        currentListViewController?.view.removeFromSuperview()
        currentListViewController = nil

        notificationToken?.invalidate()
        notificationToken = nil

        if let titleView = view.window?.toolbar?.item(withIdentifier: toolbarTitleViewIdentifier)?.view as? TitleView {
            titleView.text = ""
        }

        view.window?.makeFirstResponder(nil)
    }

    private func updateToolbar<ListType: ListPresentable>(for list: ListType) where ListType: Object {
        guard let toolbar = view.window?.toolbar else {
            return
        }

        if let titleView = toolbar.item(withIdentifier: toolbarTitleViewIdentifier)?.view as? TitleView {
            titleView.text = (list as? CellPresentable)?.text ?? "Lists"
        }

        if list is CellPresentable {
            if !toolbar.hasItem(withIdentifier: toolbarShowAllListsButtonIdentifier) {
                toolbar.insertItem(withItemIdentifier: toolbarShowAllListsButtonIdentifier, at: toolbar.items.count - 1)
            }
        } else if let index = toolbar.indexOfItem(withIdentifier: toolbarShowAllListsButtonIdentifier) {
            view.window?.toolbar?.removeItem(at: index)
        }

        // Let the new controller takes care about toolbar validation
        view.window?.makeFirstResponder(currentListViewController)
    }

}

private extension NSToolbar {

    func hasItem(withIdentifier identifier: String) -> Bool {
        return item(withIdentifier: identifier) != nil
    }

    func item(withIdentifier identifier: String) -> NSToolbarItem? {
        return items.first { $0.itemIdentifier == identifier }
    }

    func indexOfItem(withIdentifier identifier: String) -> Int? {
        return items.index { $0.itemIdentifier == identifier }
    }

}
