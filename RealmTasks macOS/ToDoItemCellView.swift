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

protocol ToDoItemCellViewDelegate: class {

    func cellView(view: ToDoItemCellView, didComplete complete: Bool)
    func cellViewDidDelete(view: ToDoItemCellView)

    func cellViewDidBeginEditing(view: ToDoItemCellView)
    func cellViewDidChangeText(view: ToDoItemCellView)
    func cellViewDidEndEditing(view: ToDoItemCellView)

}

private let iconWidth: CGFloat = 40
private let iconOffset = iconWidth / 2
private let swipeThreshold = iconWidth * 2

class ToDoItemCellView: NSTableCellView {

    weak var delegate: ToDoItemCellViewDelegate?

    var text: String {
        set {
            textView.stringValue = newValue
        }

        get {
            return textView.stringValue
        }
    }

    var completed = false {
        didSet {
            completed ? textView.strike() : textView.unstrike()
            overlayView.hidden = !completed
            overlayView.backgroundColor = completed ? .completeDimBackgroundColor() : .completeGreenBackgroundColor()
            textView.alphaValue = completed ? 0.3 : 1
            textView.editable = !completed
        }
    }

    var editable: Bool {
        set {
            textView.editable = newValue && !completed
        }

        get {
            return textView.editable
        }
    }

    var backgroundColor: NSColor {
        set {
            contentView.backgroundColor = newValue
        }

        get {
            return contentView.backgroundColor
        }
    }

    private let doneIconView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = NSImage(named: "DoneIcon")
        return imageView
    }()

    private let deleteIconView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = NSImage(named: "DeleteIcon")
        return imageView
    }()

    private let contentView = ColorView()
    private let overlayView = ColorView()
    private let textView = ToDoItemTextField()

    private var releaseAction: ReleaseAction?

    init(identifier: String) {
        super.init(frame: .zero)
        self.identifier = identifier

        setupUI()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWithToDoItem(item: ToDoItem) {
        textView.stringValue = item.text
        completed = item.completed
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        alphaValue = 1
        contentView.frame.origin.x = 0
    }

    override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        return textView.forceBecomeFirstResponder()
    }

    private func setupUI() {
        setupIconViews()
        setupContentView()
        setupOverlayView()
        setupTextView()
    }

    private func setupIconViews() {
        doneIconView.frame.size.width = iconWidth
        doneIconView.frame.origin.x = iconOffset
        doneIconView.autoresizingMask = [.ViewMaxXMargin, .ViewHeightSizable]
        addSubview(doneIconView, positioned: .Below, relativeTo: contentView)

        deleteIconView.frame.size.width = iconWidth
        deleteIconView.frame.origin.x = bounds.width - deleteIconView.bounds.width - iconOffset
        deleteIconView.autoresizingMask = [.ViewMinXMargin, .ViewHeightSizable]
        addSubview(deleteIconView, positioned: .Below, relativeTo: contentView)
    }

    private func setupContentView() {
        addSubview(contentView)

        contentView.frame = bounds
        contentView.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]

        setupBorders()
    }

    private func setupBorders() {
        let highlightLine = ColorView(backgroundColor: NSColor(white: 1, alpha: 0.05))
        let shadowLine = ColorView(backgroundColor: NSColor(white: 0, alpha: 0.05))

        contentView.addSubview(highlightLine)
        contentView.addSubview(shadowLine)

        let singlePixelInPoints = 1 / NSScreen.mainScreen()!.backingScaleFactor

        constrain(highlightLine, shadowLine) { highlightLine, shadowLine in
            highlightLine.top == highlightLine.superview!.top
            highlightLine.left == highlightLine.superview!.left
            highlightLine.right == highlightLine.superview!.right
            highlightLine.height == singlePixelInPoints

            shadowLine.bottom == shadowLine.superview!.bottom
            shadowLine.left == shadowLine.superview!.left
            shadowLine.right == shadowLine.superview!.right
            shadowLine.height == singlePixelInPoints
        }
    }

    private func setupOverlayView() {
        contentView.addSubview(overlayView)

        constrain(overlayView) { overlayView in
            overlayView.edges == overlayView.superview!.edges
        }
    }

    private func setupTextView() {
        textView.delegate = self

        contentView.addSubview(textView)

        constrain(textView) { textView in
            textView.edges == inset(textView.superview!.edges, 8, 14)
        }
    }

    private func setupGestures() {
        let recognizer = NSPanGestureRecognizer(target: self, action: #selector(handlePan))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }

}

// MARK: ToDoItemTextFieldDelegate

extension ToDoItemCellView: ToDoItemTextFieldDelegate {

    func textFieldDidBecomeFirstResponder(textField: NSTextField) {
        delegate?.cellViewDidBeginEditing(self)
    }

    override func controlTextDidChange(obj: NSNotification) {
        delegate?.cellViewDidChangeText(self)
    }

    override func controlTextDidEndEditing(obj: NSNotification) {
        delegate?.cellViewDidEndEditing(self)
    }

}

// MARK: NSGestureRecognizerDelegate

extension ToDoItemCellView: NSGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(gestureRecognizer: NSGestureRecognizer) -> Bool {
        guard gestureRecognizer is NSPanGestureRecognizer else {
            return false
        }

        let currentlyEditingTextField = ((window?.firstResponder as? NSText)?.delegate as? NSTextField)

        guard let event = NSApp.currentEvent where currentlyEditingTextField != textView else {
            return false
        }

        return fabs(event.deltaX) > fabs(event.deltaY)
    }

    private dynamic func handlePan(recognizer: NSPanGestureRecognizer) {
        let originalDoneIconOffset = iconOffset
        let originalDeleteIconOffset = bounds.width - deleteIconView.bounds.width - iconOffset

        switch recognizer.state {
        case .Began:
            window?.makeFirstResponder(nil)

            releaseAction = nil
        case .Changed:
            let translation = recognizer.translationInView(self)
            recognizer.setTranslation(translation, inView: self)

            contentView.frame.origin.x = translation.x

            if abs(translation.x) > swipeThreshold {
                doneIconView.frame.origin.x = originalDoneIconOffset + translation.x - swipeThreshold

                deleteIconView.frame.origin.x = originalDeleteIconOffset + translation.x + swipeThreshold
            } else {
                doneIconView.frame.origin.x = originalDoneIconOffset
                deleteIconView.frame.origin.x = originalDeleteIconOffset
            }

            let fractionOfThreshold = min(1, Double(abs(translation.x) / swipeThreshold))

            doneIconView.alphaValue = CGFloat(fractionOfThreshold)
            deleteIconView.alphaValue = CGFloat(fractionOfThreshold)

            releaseAction = fractionOfThreshold == 1 ? (translation.x > 0 ? .Complete : .Delete) : nil

            if completed {
                overlayView.hidden = releaseAction == .Complete
                textView.alphaValue = releaseAction == .Complete ? 1 : 0.3

                if contentView.frame.origin.x > 0 {
                    textView.strike(1 - fractionOfThreshold)
                } else {
                    releaseAction == .Complete ? textView.unstrike() : textView.strike()
                }
            } else {
                overlayView.backgroundColor = .completeGreenBackgroundColor()
                overlayView.hidden = releaseAction != .Complete

                if contentView.frame.origin.x > 0 {
                    textView.strike(fractionOfThreshold)
                } else {
                    releaseAction == .Complete ? textView.strike() : textView.unstrike()
                }
            }
        case .Ended:
            let animationBlock: () -> ()
            let completionBlock: () -> ()

            // If not deleting, slide it back into the middle
            // If we are deleting, slide it all the way out of the view
            switch releaseAction {
            case .Complete?:
                animationBlock = {
                    self.contentView.frame.origin.x = 0
                }

                completionBlock = {
                    NSView.animateWithDuration(0.2, animations: {
                        self.completed = !self.completed
                    }, completion: {
                        self.delegate?.cellView(self, didComplete: self.completed)
                    })
                }
            case .Delete?:
                animationBlock = {
                    self.alphaValue = 0

                    self.contentView.frame.origin.x = -self.contentView.bounds.width - swipeThreshold
                    self.deleteIconView.frame.origin.x = -swipeThreshold + self.deleteIconView.bounds.width + iconOffset
                }

                completionBlock = {
                    self.delegate?.cellViewDidDelete(self)
                }
            case nil:
                completed ? textView.strike() : textView.unstrike()

                animationBlock = {
                    self.contentView.frame.origin.x = 0
                }

                completionBlock = {}
            }

            NSView.animateWithDuration(0.2, animations: animationBlock) {
                completionBlock()

                self.doneIconView.frame.origin.x = originalDoneIconOffset
                self.deleteIconView.frame.origin.x = originalDeleteIconOffset
            }
        default:
            break
        }
    }

}

// MARK: Private Classes

private enum ReleaseAction {
    case Complete, Delete
}

protocol ToDoItemTextFieldDelegate: NSTextFieldDelegate {

    func textFieldDidBecomeFirstResponder(textField: NSTextField)

}

private final class ToDoItemTextField: NSTextField {

    private var _acceptsFirstResponder = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        bordered = false
        focusRingType = .None
        font = .systemFontOfSize(18)
        textColor = .whiteColor()
        backgroundColor = .clearColor()
        lineBreakMode = .ByWordWrapping
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        return _acceptsFirstResponder
    }

    override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool {
        return false
    }

    override func becomeFirstResponder() -> Bool {
        (delegate as? ToDoItemTextFieldDelegate)?.textFieldDidBecomeFirstResponder(self)

        return super.becomeFirstResponder()
    }

    func forceBecomeFirstResponder() -> Bool {
        _acceptsFirstResponder = true
        becomeFirstResponder()
        _acceptsFirstResponder = false

        return true
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrowCursor())
    }

    override var intrinsicContentSize: NSSize {
        // By default editable NSTextField doesn't respect wrapping while calculating intrinsic content size,
        // let's calculate the correct one by ourselves
        let placeholderFrame = NSRect(origin: .zero, size: NSSize(width: frame.width, height: .max))
        let calculatedHeight = cell!.cellSizeForBounds(placeholderFrame).height

        return NSSize(width: frame.width, height: calculatedHeight)
    }

    override func textDidChange(notification: NSNotification) {
        super.textDidChange(notification)

        // Update height on text change
        invalidateIntrinsicContentSize()
    }

}

private final class ColorView: NSView {

    var backgroundColor = NSColor.clearColor() {
        didSet {
            needsDisplay = true
        }
    }

    convenience init(backgroundColor: NSColor) {
        self.init(frame: .zero)
        self.backgroundColor = backgroundColor
    }

    override func drawRect(dirtyRect: NSRect) {
        backgroundColor.setFill()
        NSRectFillUsingOperation(dirtyRect, .CompositeSourceOver)
    }

}

// MARK: Private Extensions

private extension NSTextField {

    func strike(fraction: Double = 1) {
        if fraction < 1 {
            unstrike()
        }

        setAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.StyleThick.rawValue, range: NSMakeRange(0, Int(fraction * Double(stringValue.characters.count))))
    }

    func unstrike() {
        setAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.StyleNone.rawValue)
    }

    private func setAttribute(name: String, value: AnyObject, range: NSRange? = nil) {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedStringValue)
        mutableAttributedString.addAttribute(name, value: value, range: range ?? NSMakeRange(0, mutableAttributedString.length))
        attributedStringValue = mutableAttributedString
    }

}
