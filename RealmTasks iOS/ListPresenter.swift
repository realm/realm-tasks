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
    var bounds: CGRect {get}

    func skipNextNotification()
    func updateColors(completion completion: (() -> Void)?)
    func toggleOnboardView(animated animated: Bool)

    func setTopConstraint(constant: CGFloat)
    func setPlaceholderAlpha(alpha: CGFloat)
}

class ListPresenter<Parent: Object where Parent: ListPresentable>: NSObject, ListPresenterProtocol {
    let editingCellAlpha: CGFloat = 0.3

    // Connections
    var viewController: ListViewControllerProtocol!
    var items: ItemsInteractor<Parent>!
    var cellInteractor: CellInteractor<Parent>!

    var parent: Parent {
        return items.tasks.parent
    }

    // Editing properties
    var currentlyEditingCell: TableViewCell<Parent.Item>? {
        didSet {
            viewController.tableView.scrollEnabled = (currentlyEditingCell == nil)
        }
    }
    var currentlyEditingIndexPath: NSIndexPath?


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

    func updateListForChangedCell(editingCell: TableViewCell<Parent.Item>) {
        // If the height of the text view has extended to the next line,
        // reload the height of the cell
        let height = cellHeightForText(editingCell.textView.text)
        if Int(height) != Int(editingCell.frame.size.height) {
            UIView.performWithoutAnimation {[unowned self] in
                self.viewController.tableView.beginUpdates()
                self.viewController.tableView.endUpdates()
            }

            for cell in viewController.tableView.visibleCells where cell !== editingCell {
                cell.alpha = editingCellAlpha
            }
        }
    }

    func cellDidBeginEditing(editingCell: TableViewCell<Parent.Item>) {
        currentlyEditingCell = editingCell
        let tableView = viewController.tableView

        currentlyEditingIndexPath = tableView.indexPathForCell(editingCell)

        let editingOffset = editingCell.convertRect(editingCell.bounds, toView: tableView).origin.y - tableView.contentOffset.y - tableView.contentInset.top
        viewController.setTopConstraint( -editingOffset)
        tableView.contentInset.bottom += editingOffset

        viewController.setPlaceholderAlpha(0)
        tableView.bounces = false

        UIView.animateWithDuration(0.3, animations: { [unowned self] in
            tableView.superview?.layoutSubviews()
            for cell in tableView.visibleCells where cell !== editingCell {
                cell.alpha = self.editingCellAlpha
            }
            }, completion: { [unowned self] finished in
                self.viewController.tableView.bounces = true
            })
    }

    func cellDidEndEditing(editingCell: TableViewCell<Parent.Item>) {
        currentlyEditingCell = nil
        currentlyEditingIndexPath = nil

        let tableView = viewController.tableView

        tableView.contentInset.bottom = 54
        viewController.setTopConstraint(0)
        UIView.animateWithDuration(0.3) {
            for cell in tableView.visibleCells where cell !== editingCell {
                cell.alpha = 1
            }
            tableView.superview?.layoutSubviews()
        }

        let item = editingCell.item
        guard !(item as Object).invalidated else {
            tableView.reloadData()
            return
        }
        if item.text.isEmpty {
            try! item.realm?.write {
                item.realm!.delete(item)
            }
            tableView.deleteRowsAtIndexPaths([tableView.indexPathForCell(editingCell)!], withRowAnimation: .None)
        }
        viewController.skipNextNotification()
        viewController.toggleOnboardView(animated: false)
    }

    internal func cellHeightForText(text: String) -> CGFloat {
        return text.boundingRectWithSize(CGSize(width: viewController.bounds.size.width - 25, height: viewController.bounds.size.height),
                                         options: [.UsesLineFragmentOrigin],
                                         attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18)],
                                         context: nil).height + 33
    }

}