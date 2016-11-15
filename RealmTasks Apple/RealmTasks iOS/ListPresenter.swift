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

import Foundation
import RealmSwift
import UIKit

private var titleKVOContext = 0

class ListPresenter<Item: Object, Parent: Object where Item: CellPresentable, Parent: ListPresentable, Parent.Item == Item>: NSObject {

    var cellPresenter: CellPresenter<Item>!
    var tablePresenter: TablePresenter<Parent>!

    internal var notificationToken: NotificationToken?

    var viewController: ViewControllerProtocol! {
        didSet {
            cellPresenter.viewController = viewController
            tablePresenter.viewController = viewController

            if viewController != nil {
                observeListTitle()
            } else if observingText {
                parent.removeObserver(self, forKeyPath: "text")
            }

            notificationToken = setupNotifications()
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

    func observeListTitle() {
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
    private func setupNotifications() -> NotificationToken {
        return parent.items.addNotificationBlock { [unowned self] changes in
            switch changes {
            case .Initial:
                // Results are now populated and can be accessed without blocking the UI
                self.viewController.didUpdateList(reload: true)
            case .Update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                self.viewController.tableView.beginUpdates()
                self.viewController.tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
                self.viewController.tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
                self.viewController.tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                self.viewController.tableView.endUpdates()
                self.viewController.didUpdateList(reload: false)
            case .Error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError(String(error))
            }
        }
    }

    // MARK: Onboarding
    lazy var onboardView: OnboardView = {
        return .add(inView: self.viewController.tableView)
    }()

    func updateOnboardView(animated: Bool = false) {
        onboardView.toggle(animated: animated, isVisible: parent.items.isEmpty)
    }

    func setOnboardAlpha(alpha: CGFloat) {
        if parent.items.isEmpty {
            onboardView.alpha = alpha
        } else {
            updateOnboardView()
        }
    }
}
