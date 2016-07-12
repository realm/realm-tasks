//
//  ToDoListCell.swift
//  RealmClear
//
//  Created by kishikawa katsumi on 7/8/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit
import Cartography

protocol ToDoListCellDelegate {
    func willCompleteList(list: ToDoList)
    func willDeleteList(list: ToDoList)
    func cellDidBeginEditing(editingCell: ToDoListCell)
    func cellDidEndEditing(editingCell: ToDoListCell)
    func cellDidChangeText(editingCell: ToDoListCell)
}

final class ToDoListCell: UITableViewCell, UITextViewDelegate {
    var list: ToDoList! {
        didSet {
            textView.text = list.title
        }
    }
    var delegate: ToDoListCellDelegate?
    let textView = ToDoItemTextView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None

        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        setupBackgroundView()
        setupTextView()
    }

    private func setupBackgroundView() {
        backgroundColor = .clearColor()

        backgroundView = UIView()
        constrain(backgroundView!) { backgroundView in
            backgroundView.edges == backgroundView.superview!.edges
        }
    }

    private func setupTextView() {
        textView.editable = true
        textView.textColor = .whiteColor()
        textView.font = .systemFontOfSize(18)
        textView.backgroundColor = .clearColor()
        textView.userInteractionEnabled = false
        textView.keyboardAppearance = .Dark
        textView.returnKeyType = .Done
        textView.scrollEnabled = false

        textView.delegate = self

        contentView.addSubview(textView)
        constrain(textView) { textView in
            textView.left == textView.superview!.left + 8
            textView.top == textView.superview!.top + 8
            textView.bottom == textView.superview!.bottom - 8
            textView.right == textView.superview!.right - 8
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        alpha = 1.0
        contentView.alpha = 1.0
    }

    // MARK: UITextViewDelegate methods

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    func textViewDidBeginEditing(textView: UITextView) {
        delegate?.cellDidBeginEditing(self)
    }

    func textViewDidEndEditing(textView: UITextView) {
        if let realm = list.realm {
            try! realm.write {
                list.title = textView.text
            }
        } else {
            list.title = textView.text
        }
        textView.userInteractionEnabled = false
        delegate?.cellDidEndEditing(self)
    }

    func textViewDidChange(textView: UITextView) {
        delegate?.cellDidChangeText(self)
    }
}

final class SeparatorCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None
        backgroundColor = .blackColor()

        backgroundView = UIView()
        constrain(backgroundView!) { backgroundView in
            backgroundView.edges == backgroundView.superview!.edges
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
