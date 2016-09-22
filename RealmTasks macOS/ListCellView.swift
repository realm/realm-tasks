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

import Cocoa
import Cartography

class ListCellView: TaskCellView {

    private let countLabel = NSTextField()

    private var editing = false

    override init(identifier: String) {
        super.init(identifier: identifier)

        setupCountBadge()

        textView.layer?.cornerRadius = 5

        setTrackingAreaWithRect(bounds, options: [.MouseEnteredAndExited, .ActiveInKeyWindow])
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

    override func configure(item: CellPresentable) {
        guard let list = item as? TaskList else {
            fatalError("Wrong item type")
        }

        super.configure(list)

        let count = list.items.filter("completed == false").count

        countLabel.integerValue = count
        countLabel.alphaValue = count == 0 ? 0.3 : 1
        textView.alphaValue = count == 0 ? 0.3 : 1

        editable = false
    }

    override func updateTrackingAreas() {
        setTrackingAreaWithRect(bounds, options: [.MouseEnteredAndExited, .ActiveInKeyWindow])
    }

    override func mouseEntered(theEvent: NSEvent) {
        super.mouseEntered(theEvent)

        performSelector(#selector(delayedSetEditable), withObject: nil, afterDelay: 1.2)
    }

    override func mouseExited(theEvent: NSEvent) {
        super.mouseExited(theEvent)

        guard !editing else {
            return
        }

        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(delayedSetEditable), object: nil)

        editable = false
        textView.backgroundColor = .clearColor()
    }

    private dynamic func delayedSetEditable() {
        editable = true
        textView.backgroundColor = NSColor(white: 0, alpha: 0.3)

        NSCursor.IBeamCursor().set()
    }

//    override func textFieldDidBecomeFirstResponder(textField: NSTextField) {
//        super.textFieldDidBecomeFirstResponder(textField)
//
//        editing = true
//    }

    override func controlTextDidEndEditing(obj: NSNotification) {
        super.controlTextDidEndEditing(obj)

        editing = false
        editable = false
        textView.backgroundColor = .clearColor()
    }

}
