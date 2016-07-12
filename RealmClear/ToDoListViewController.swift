//
//  ToDoListViewController.swift
//  RealmClear
//
//  Created by kishikawa katsumi on 7/8/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit
import Cartography
import RealmSwift

final class ToDoListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ToDoListCellDelegate {
    private var lists = try! Realm().objects(ToDoList).sorted("order", ascending: false)

    private let tableView = UITableView()
    private var visibleTableViewCells: [UITableViewCell] { return tableView.visibleCells }
    
    private var topConstraint: NSLayoutConstraint?

    private let placeHolderContainerView = UIView()
    private let textEditingCell = ToDoListCell(style: .Default, reuseIdentifier: "cell")

    private let cellHeight: CGFloat = 44.0
    private let separatorHeight: CGFloat = 10.0
    private let editingCellAlpha: CGFloat = 0.3

    // Scrolling
    var distancePulledDown: CGFloat {
        return -tableView.contentOffset.y - tableView.contentInset.top
    }
    var distancePulledUp: CGFloat {
        return tableView.contentOffset.y + tableView.bounds.size.height - max(tableView.bounds.size.height, tableView.contentSize.height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    private func setupUI() {
        setupTableView()
        setupPlaceholderCell()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        constrain(tableView) { tableView in
            topConstraint = (tableView.top == tableView.superview!.top)
            tableView.right == tableView.superview!.right
            tableView.bottom == tableView.superview!.bottom
            tableView.left == tableView.superview!.left
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(ToDoListCell.self, forCellReuseIdentifier: "cell")
        tableView.registerClass(SeparatorCell.self, forCellReuseIdentifier: "separator")
        tableView.separatorStyle = .None
        tableView.backgroundColor = .blackColor()
        tableView.contentInset = UIEdgeInsets(top: UIApplication.sharedApplication().statusBarFrame.height,
                                              left: 0,
                                              bottom: cellHeight,
                                              right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
        tableView.showsVerticalScrollIndicator = false
    }

    private func setupPlaceholderCell() {
        placeHolderContainerView.alpha = 0
        placeHolderContainerView.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        tableView.addSubview(placeHolderContainerView)
        constrain(placeHolderContainerView) { placeHolderContainerView in
            placeHolderContainerView.bottom == placeHolderContainerView.superview!.topMargin + 18
            placeHolderContainerView.left == placeHolderContainerView.superview!.superview!.left
            placeHolderContainerView.right == placeHolderContainerView.superview!.superview!.right
            placeHolderContainerView.height == cellHeight + separatorHeight
        }

        let placeHolderCell = ToDoListCell(style: .Default, reuseIdentifier: "cell")
        placeHolderCell.backgroundView!.backgroundColor = UIColor.realmColors[5]
        placeHolderContainerView.addSubview(placeHolderCell)
        constrain(placeHolderCell) { placeHolderCell in
            placeHolderCell.top == placeHolderCell.superview!.top
            placeHolderCell.left == placeHolderCell.superview!.left
            placeHolderCell.right == placeHolderCell.superview!.right
            placeHolderCell.height == cellHeight
        }

        let placeHolderSeparator = SeparatorCell(style: .Default, reuseIdentifier: "separator")
        placeHolderContainerView.addSubview(placeHolderSeparator)
        constrain(placeHolderSeparator) { placeHolderSeparator in
            placeHolderSeparator.bottom == placeHolderSeparator.superview!.bottom
            placeHolderSeparator.left == placeHolderSeparator.superview!.left
            placeHolderSeparator.right == placeHolderSeparator.superview!.right
            placeHolderSeparator.height == separatorHeight
        }
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return lists.count * 2 // Cell + separator
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section % 2 == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! ToDoListCell

            cell.list = lists[indexPath.section / 2]
            cell.delegate = self

//            if let editingIndexPath = currentlyEditingIndexPath {
//                if editingIndexPath.row != indexPath.row { cell.alpha = editingCellAlpha }
//            }

            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("separator", forIndexPath: indexPath)
            return cell
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section % 2 == 0 ? cellHeight : separatorHeight
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section % 2 == 0 {
            cell.contentView.backgroundColor = UIColor.realmColors[5]
        }
    }

    // MARK: UIScrollViewDelegate methods

    func scrollViewDidScroll(scrollView: UIScrollView)  {
        guard distancePulledDown > 0 else { return }

        let placeholderHeight = cellHeight + separatorHeight
        if distancePulledDown <= placeholderHeight {
//            placeHolderContainerView.textView.text = "Pull to Create"

            let angle = CGFloat(degreesToRadians(90)) - tan(distancePulledDown / placeholderHeight)

            var transform = CATransform3DIdentity
            transform.m34 = 1.0 / -(1000 * 0.2)
            transform = CATransform3DRotate(transform, angle, 1.0, 0.0, 0.0)

            placeHolderContainerView.layer.transform = transform
        } else {
            placeHolderContainerView.layer.transform = CATransform3DIdentity
//            placeHolderContainerView.textView.text = "Release to Create"
        }

        if scrollView.dragging {
            placeHolderContainerView.alpha = min(1, distancePulledDown / placeholderHeight)
        }
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard distancePulledDown > cellHeight else { return }

        // exceeds threshold
        textEditingCell.frame = placeHolderContainerView.bounds
        textEditingCell.frame.origin.y = tableView.contentInset.top + (distancePulledDown - cellHeight - separatorHeight)
        textEditingCell.frame.size.height = cellHeight
        print(placeHolderContainerView.subviews)
        textEditingCell.backgroundView!.backgroundColor = UIColor.realmColors[5]
        view.addSubview(textEditingCell)

        textEditingCell.list = ToDoList(title: "")
        textEditingCell.delegate = self

        textEditingCell.textView.userInteractionEnabled = true
        textEditingCell.textView.becomeFirstResponder()
    }

    // MARK: ToDoListCellDelegate

    func willCompleteList(list: ToDoList) {}
    func willDeleteList(list: ToDoList) {}

    func cellDidBeginEditing(editingCell: ToDoListCell) {
//        currentlyEditingCell = editingCell
//        currentlyEditingIndexPath = tableView.indexPathForCell(editingCell)

        let editingOffset = editingCell.convertRect(editingCell.bounds, toView: tableView).origin.y
        topConstraint?.constant = -editingOffset

        placeHolderContainerView.alpha = 0.0
        tableView.bounces = false

        UIView.animateWithDuration(0.3, animations: { [unowned self] in
            self.view.layoutSubviews()
            self.textEditingCell.frame.origin.y = self.tableView.contentInset.top
            for cell in self.visibleTableViewCells where cell !== editingCell {
                cell.alpha = self.editingCellAlpha
            }
            }, completion: { [unowned self] finished in
                self.tableView.bounces = true
            })
    }

    func cellDidEndEditing(editingCell: ToDoListCell) {
//        currentlyEditingCell = nil
//        currentlyEditingIndexPath = nil

        topConstraint?.constant = 0
        UIView.animateWithDuration(0.3) { [weak self] in
            guard let strongSelf = self else { return }
            for cell in strongSelf.visibleTableViewCells where cell !== editingCell {
                cell.alpha = 1
            }
        }

        if let list = editingCell.list where editingCell == textEditingCell && !list.title.isEmpty {
            if let realm = lists.realm {
                try! realm.write {
                    list.order = lists.count
                    realm.add(list)
                }
            }

            UIView.performWithoutAnimation {
                self.tableView.insertSections(NSIndexSet(indexesInRange: NSRange(0...1)), withRowAnimation: .None)
            }
//            temporarilyDisableNotifications()
        } else {
            UIView.animateWithDuration(0.3) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.view.layoutSubviews()
            }
        }

        if let _ = textEditingCell.superview {
            textEditingCell.removeFromSuperview()
        }
    }
    
    func cellDidChangeText(editingCell: ToDoListCell) {}

}
