//
//  ListCellView.swift
//  RealmTasks
//
//  Created by Dmitry Obukhov on 07/09/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Cocoa
import Cartography

class ListCellView: TaskCellView {

    private let countLabel = NSTextField()

    override init(identifier: String) {
        super.init(identifier: identifier)

        setupCountBadge()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCountBadge() {
        let badgeBackgroundView = ColorView(backgroundColor: NSColor.whiteColor().colorWithAlphaComponent(0.15))

        contentView.addSubview(badgeBackgroundView)
        constrain(badgeBackgroundView) { badgeBackgroundView in
            badgeBackgroundView.top == badgeBackgroundView.superview!.top
            badgeBackgroundView.bottom == badgeBackgroundView.superview!.bottom
            badgeBackgroundView.right == badgeBackgroundView.superview!.right
            badgeBackgroundView.width == badgeBackgroundView.height
        }

        countLabel.usesSingleLineMode = true
        countLabel.bordered = false
        countLabel.focusRingType = .None
        countLabel.font = .systemFontOfSize(18)
        countLabel.textColor = .whiteColor()
        countLabel.backgroundColor = .clearColor()
        countLabel.alignment = .Center
        countLabel.editable = false

        badgeBackgroundView.addSubview(countLabel)
        constrain(countLabel) { countLabel in
            countLabel.width == countLabel.superview!.width
            countLabel.height == 19
            countLabel.center == countLabel.superview!.center
        }
    }

    override func configureWithTask(item: CellPresentable) {
        super.configureWithTask(item)

        if let item = item as? TaskList {
            let count = item.items.filter("completed == false").count

            countLabel.integerValue = count

            if count == 0 {
                textView.alphaValue = 0.3
                countLabel.alphaValue = 0.3
            } else {
                countLabel.alphaValue = 1
            }
        }
    }

    override func textFieldDidBecomeFirstResponder(textField: NSTextField) {
        
    }

}
