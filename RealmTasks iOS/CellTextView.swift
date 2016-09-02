/*************************************************************************
 *
 * REALM CONFIDENTIAL
 * __________________
 *
 *  [2016] Realm Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of Realm Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to Realm Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Realm Incorporated.
 *
 **************************************************************************/

import UIKit

final class CellTextView: UITextView {

    // MARK: Initializers

    init() {
        super.init(frame: .null, textContainer: nil)
        editable = true
        textColor = .whiteColor()
        font = .systemFontOfSize(18)
        backgroundColor = .clearColor()
        userInteractionEnabled = false
        keyboardAppearance = .Dark
        autocapitalizationType = .Words
        returnKeyType = .Done
        scrollEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Actions

    func strike(fraction: Double = 1) {
        let mutableAttributedString = attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSRange(location: 0, length: Int(fraction * Double(mutableAttributedString.length))))
        attributedText = mutableAttributedString.copy() as? NSAttributedString
    }

    func unstrike() {
        var mutableTypingAttributes = typingAttributes
        mutableTypingAttributes.removeValueForKey(NSStrikethroughStyleAttributeName)
        typingAttributes = mutableTypingAttributes
        let mutableAttributedString = attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.removeAttribute(NSStrikethroughStyleAttributeName, range: NSRange(location: 0, length: mutableAttributedString.length))
        attributedText = mutableAttributedString.copy() as? NSAttributedString
    }
}
