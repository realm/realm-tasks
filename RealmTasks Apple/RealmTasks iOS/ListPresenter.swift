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

class ListPresenter<Item: Object, Parent: Object>: NSObject where Item: CellPresentable, Parent: ListPresentable, Parent.Item == Item {

    var cellPresenter: CellPresenter<Item>!
    var tablePresenter: TablePresenter<Parent>!

    private var notificationToken: NotificationToken?

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
            (parent as! Object).addObserver(self, forKeyPath: "text", options: .new, context: &titleKVOContext)
            viewController.setListTitle(title: parent.text)
            observingText = true
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &titleKVOContext {
            viewController.setListTitle(title: (parent as! CellPresentable).text)
        }
    }

    // MARK: Notifications
    private func setupNotifications() -> NotificationToken {
        return parent.items.addNotificationBlock { [unowned self] changes in
            // Do not perform an update if the user is editing a cell at this moment
            // (The table will be reloaded by the 'end editing' call of the active cell)
            guard self.cellPresenter.currentlyEditingCell == nil else {
                return
            }

            self.viewController.tableView.reloadData()
        }
    }

    // MARK: Onboarding
    lazy var onboardView: OnboardView = {
        return OnboardView.add(inView: self.viewController.tableView)
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
