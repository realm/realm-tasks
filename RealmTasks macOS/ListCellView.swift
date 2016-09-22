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

class ListCellView: ItemCellView {

    private let countLabel = NSTextField()

    private(set) var acceptsEditing = false {
        didSet {
            textView.backgroundColor = acceptsEditing ? NSColor(white: 0, alpha: 0.3) : .clearColor()
            window?.invalidateCursorRectsForView(self)
        }
    }

    override var editable: Bool {
        didSet {
            acceptsEditing = false
        }
    }

    required init(identifier: String) {
        super.init(identifier: identifier)

        setupCountBadge()

        textView.layer?.cornerRadius = 5
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

        countLabel.integerValue = list.items.filter("completed == false").count
        editable = false

        updateTextColor()
    }

    private func updateTextColor() {
        NSView.animate(duration: 0.1) {
            self.countLabel.alphaValue = self.countLabel.integerValue == 0 ? 0.3 : 1
            self.textView.alphaValue = self.countLabel.integerValue == 0 ? 0.3 : 1
        }
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: acceptsEditing ? .IBeamCursor() : .arrowCursor())
    }

    override func mouseEntered(theEvent: NSEvent) {
        super.mouseEntered(theEvent)

        guard !editable else {
            return
        }

        NSView.animate(duration: 0.1) {
            self.countLabel.alphaValue = 1
            self.textView.alphaValue = 1
        }

        performSelector(#selector(delayedSetAcceptEditing), withObject: nil, afterDelay: 1.2)
    }

    override func mouseExited(theEvent: NSEvent) {
        super.mouseExited(theEvent)

        guard !editable else {
            return
        }

        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(delayedSetAcceptEditing), object: nil)
        acceptsEditing = false

        updateTextColor()
    }

    private dynamic func delayedSetAcceptEditing() {
        acceptsEditing = true
    }

    override func controlTextDidEndEditing(obj: NSNotification) {
        super.controlTextDidEndEditing(obj)

        acceptsEditing = false
    }

}
