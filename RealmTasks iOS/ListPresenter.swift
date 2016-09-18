//
//  ListPresenter.swift
//  RealmTasks
//
//  Created by Marin Todorov on 9/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import RealmSwift

private var titleKVOContext = 0

protocol ListViewControllerProtocol {
    func shareDialogueWithUrl(shareUrl: String)
    func setListTitle(title: String)
}

class ListPresenter<Parent: Object where Parent: ListPresentable>: NSObject {

    var viewController: ListViewControllerProtocol!
    var items: ItemsInteractor<Parent>!
    var parent: Parent {
        return items.tasks.parent
    }

    convenience init(parent: Parent) {
        self.init()
        items = ItemsInteractor(parent: parent)
    }

    deinit {
        parent.removeObserver(self, forKeyPath: "text")
    }

    func allItems() -> List<Parent.Item> {
        return items.tasks.parent.items
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &titleKVOContext {
            if let parent = parent as? TaskList {
                viewController.setListTitle(parent.text)
            }
        }
    }

    func observeTitle() {
        if let parent = parent as? TaskList {
            parent.addObserver(self, forKeyPath: "text", options: .New, context: &titleKVOContext)
            viewController.setListTitle(parent.text)
        }
    }
}