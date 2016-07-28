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
    
    func cellViewDidBeginEditing(editingCell: ToDoItemCellView)
    func cellViewDidEndEditing(editingCell: ToDoItemCellView)
    func cellViewDidChangeText(editingCell: ToDoItemCellView)

}

class ToDoItemCellView: NSTableCellView {
    
    weak var delegate: ToDoItemCellViewDelegate?
    
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
    
    private var originalDoneIconOffset: CGFloat = 0.0
    private var originalDeleteIconOffset: CGFloat = 0.0
    
    private var releaseAction: ReleaseAction?
    
    private var completed = false {
        didSet {
            completed ? textView.strike() : textView.unstrike()
            overlayView.hidden = !completed
            overlayView.backgroundColor = completed ? .completeDimBackgroundColor() : .completeGreenBackgroundColor()
            textView.alphaValue = completed ? 0.3 : 1
            textView.editable = !completed
        }
    }
    
    init(identifier: String) {
        super.init(frame: .zero)
        self.identifier = identifier
        
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UI
    
    private func setupUI() {
        setupIconViews()
        setupContentView()
        setupOverlayView()
        setupTextView()
    }
    
    private func setupIconViews() {
        doneIconView.alphaValue = 0.0
        doneIconView.frame.size.width = 40
        doneIconView.frame.origin.x = 20
        doneIconView.autoresizingMask = [.ViewMaxXMargin, .ViewHeightSizable]
        addSubview(doneIconView, positioned: .Below, relativeTo: contentView)
        
        deleteIconView.alphaValue = 0.0
        deleteIconView.frame.size.width = 40
        deleteIconView.frame.origin.x = bounds.width - deleteIconView.bounds.width - 20
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
            textView.centerY == textView.superview!.centerY
            textView.left == textView.superview!.left + 8
            textView.right == textView.superview!.right - 8
        }
    }
    
    private func setupGestures() {
        let recognizer = NSPanGestureRecognizer(target: self, action: #selector(handlePan))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }
    
    func configureWithToDoItem(item: ToDoItem) {
        textView.stringValue = item.text
        completed = item.completed
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        alphaValue = 1.0
        contentView.frame.origin.x = 0.0
    }
    
    private dynamic func handlePan(recognizer: NSPanGestureRecognizer) {
        switch recognizer.state {
        case .Began:
            window?.makeFirstResponder(nil)
            
            originalDeleteIconOffset = deleteIconView.frame.origin.x
            originalDoneIconOffset = doneIconView.frame.origin.x
        case .Changed:
            let translation = recognizer.translationInView(self)
            recognizer.setTranslation(translation, inView: self)
            
            contentView.frame.origin.x = translation.x
            
            let fractionOfThreshold = min(1, Double(abs(translation.x) / (bounds.size.width / 4)))
            releaseAction = fractionOfThreshold >= 1 ? (translation.x > 0 ? .Complete : .Delete) : nil
            
            if abs(translation.x) > (frame.size.width / 4) {
                let x = abs(translation.x) - (frame.size.width / 4)
                doneIconView.setFrameOrigin(NSPoint(x: originalDoneIconOffset + x, y: doneIconView.frame.origin.y))
                deleteIconView.setFrameOrigin(NSPoint(x: originalDeleteIconOffset - x, y: deleteIconView.frame.origin.y))
            }
            
            if translation.x > 0.0 {
                doneIconView.alphaValue = CGFloat(fractionOfThreshold)
            } else {
                deleteIconView.alphaValue = CGFloat(fractionOfThreshold)
            }
            
            if completed {
                overlayView.hidden = releaseAction == .Complete
                textView.alphaValue = releaseAction == .Complete ? 1 : 0.3
                
                if frame.origin.x > 0 {
                    textView.strike()
                } else {
                    releaseAction == .Complete ? textView.unstrike() : textView.strike()
                }
            } else {
                overlayView.backgroundColor = .completeGreenBackgroundColor()
                overlayView.hidden = releaseAction != .Complete
                
                if frame.origin.x > 0 {
                    textView.strike()
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
                    self.contentView.frame.origin.x = 0.0
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
                    self.alphaValue = 0.0
                    
                    self.contentView.frame.origin.x = -self.contentView.bounds.width - (self.bounds.size.width / 4)
                    self.deleteIconView.frame.origin.x = -(self.bounds.size.width / 4) + self.deleteIconView.bounds.width + 20
                }
                
                completionBlock = {
                    self.delegate?.cellViewDidDelete(self)
                }
            case nil:
                completed ? textView.strike() : textView.unstrike()
                
                animationBlock = {
                    self.contentView.frame.origin.x = 0.0
                }
                
                completionBlock = {}
            }
            
            NSView.animateWithDuration(0.2, animations: animationBlock) {
                completionBlock()
                
                self.doneIconView.frame.origin.x = 20
                self.doneIconView.alphaValue = 0.0
                
                self.deleteIconView.frame.origin.x = self.bounds.width - self.deleteIconView.bounds.width - 20
                self.deleteIconView.alphaValue = 0.0
            }
        default:
            break
        }
    }

}

extension ToDoItemCellView: NSTextFieldDelegate {
    
    // TODO: Implement editing
    
}

extension ToDoItemCellView: NSGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(gestureRecognizer: NSGestureRecognizer) -> Bool {
        guard gestureRecognizer is NSPanGestureRecognizer else {
            return false
        }
        
        guard let event = NSApp.currentEvent else {
            return false
        }
        
        return fabs(event.deltaX) > fabs(event.deltaY)
    }
    
}

// MARK: Private Classes

private enum ReleaseAction {
    case Complete, Delete
}

private final class ToDoItemTextField: NSTextField {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        bordered = false
        focusRingType = .None
        font = .systemFontOfSize(18)
        textColor = .whiteColor()
        backgroundColor = .clearColor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var acceptsFirstResponder: Bool {
        return false
    }
    
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrowCursor())
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
    
    func strike() {
        setAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.StyleThick.rawValue)
    }
    
    func unstrike() {
        setAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.StyleNone.rawValue)
    }
    
    private func setAttribute(name: String, value: AnyObject) {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedStringValue)
        mutableAttributedString.addAttribute(name, value: value, range: NSMakeRange(0, mutableAttributedString.length))
        attributedStringValue = mutableAttributedString
    }

}
