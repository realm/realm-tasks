//
//  ToDoTextView.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit

class ToDoItemTextView: UITextView {
    init() {
        super.init(frame: .null, textContainer: nil)
        editable = true
        textColor = .whiteColor()
        font = .systemFontOfSize(18)
        backgroundColor = .clearColor()
        userInteractionEnabled = false
        keyboardAppearance = .Dark
        returnKeyType = .Done
        scrollEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
