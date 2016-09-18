//
//  ListPresenter.swift
//  RealmTasks
//
//  Created by Marin Todorov on 9/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

private var titleKVOContext = 0

protocol ListViewControllerProtocol {
    func shareDialogueWithUrl(shareUrl: String)
    func setListTitle(title: String)

    var tableView: UITableView {get}

    func skipNextNotification()
    func updateColors(completion completion: (() -> Void)?)
    func toggleOnboardView(animated animated: Bool)
}

class ListPresenter<Parent: Object where Parent: ListPresentable>: NSObject, ListPresenterProtocol {

    var viewController: ListViewControllerProtocol!
    var items: ItemsInteractor<Parent>!
    var cellInteractor: CellInteractor<Parent>!

    var parent: Parent {
        return items.tasks.parent
    }

    convenience init(parent: Parent) {
        self.init()
        items = ItemsInteractor(parent: parent)
        cellInteractor = CellInteractor(parent: parent)
        cellInteractor.presenter = self
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

    //MARK: Sharing
    func shareCurrentList() {
        guard let taskList = parent as? TaskList else {
            return
        }

        let share = ShareInteractor()
        share.presenter = self
        share.share(taskList)
    }

    func shareListUrl(urlString: String) {
        viewController.shareDialogueWithUrl(urlString)
    }

    //MARK: Cell callbacks
    func completeCellWithItem(item: Parent.Item) {
        cellInteractor.completeCellItem(item)
    }

    func moveCell(from from: NSIndexPath, to: NSIndexPath) {
        viewController.tableView.moveRowAtIndexPath(from, toIndexPath: to)
        refreshTableAfterUpdate()
    }

    func refreshTableAfterUpdate() {
        viewController.skipNextNotification()
        viewController.updateColors(completion: nil)
        viewController.toggleOnboardView(animated: false)
    }

    func deleteCellWithItem(item: Parent.Item) {
        cellInteractor.deleteCellItem(item)
    }

    func deleteCell(from from: [NSIndexPath], withRowAnimation: UITableViewRowAnimation) {
        viewController.tableView.deleteRowsAtIndexPaths(from, withRowAnimation: withRowAnimation)
        refreshTableAfterUpdate()
    }
}