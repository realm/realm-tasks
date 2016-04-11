//
//  TableViewCell.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import AudioToolbox
import Cartography
import UIKit

protocol TableViewCellDelegate {
    func itemCompleted(item: ToDoItem)
    func itemDeleted(item: ToDoItem)
}

extension UIColor {
    static func completeDimBackgroundColor() -> UIColor {
        return UIColor(white: 0.2, alpha: 1)
    }

    static func completeGreenBackgroundColor() -> UIColor {
        return UIColor(red: 0, green: 0.6, blue: 0, alpha: 1)
    }
}

enum ReleaseAction {
    case Complete, Delete
}

private let isDevice = TARGET_OS_SIMULATOR == 0

class TableViewCell: UITableViewCell, UITextViewDelegate {
    var item: ToDoItem! {
        didSet {
            textView.text = item.text
            setCompleted(item.completed)
        }
    }
    var delegate: TableViewCellDelegate?
    let textView = ToDoItemTextView()
    var originalCenter = CGPoint()
    var releaseAction: ReleaseAction?
    let backgroundOverlayView = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None

        setupUI()
        setupPanGestureRecognizer()
    }

    // MARK: UI

    func setupUI() {
        setupBackgroundOverlayView()
        setupTextView()
        setupBorders()
    }

    func setupBackgroundOverlayView() {
        backgroundOverlayView.backgroundColor = .completeDimBackgroundColor()
        backgroundOverlayView.hidden = true
        addSubview(backgroundOverlayView)
        constrain(backgroundOverlayView) { backgroundOverlayView in
            backgroundOverlayView.edges == backgroundOverlayView.superview!.edges
        }
    }

    func setupTextView() {
        textView.delegate = self
        addSubview(textView)
        constrain(textView) { textView in
            textView.left == textView.superview!.left + 8
            textView.top == textView.superview!.top + 8
            textView.bottom == textView.superview!.bottom
            textView.right == textView.superview!.right
        }
    }

    private func setupBorders() {
        let singlePixelInPoints = 1 / UIScreen.mainScreen().scale

        let highlightLine = UIView()
        highlightLine.backgroundColor = UIColor(white: 1, alpha: 0.05)
        addSubview(highlightLine)
        constrain(highlightLine) { highlightLine in
            highlightLine.top == highlightLine.superview!.top
            highlightLine.left == highlightLine.superview!.left
            highlightLine.right == highlightLine.superview!.right
            highlightLine.height == singlePixelInPoints
        }

        let shadowLine = UIView()
        shadowLine.backgroundColor = UIColor(white: 0, alpha: 0.05)
        addSubview(shadowLine)
        constrain(shadowLine) { shadowLine in
            shadowLine.bottom == shadowLine.superview!.bottom
            shadowLine.left == shadowLine.superview!.left
            shadowLine.right == shadowLine.superview!.right
            shadowLine.height == singlePixelInPoints
        }
    }

    // MARK: Pan Gesture Recognizer

    func setupPanGestureRecognizer() {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }

    func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .Began:
            originalCenter = center
            releaseAction = nil
            break
        case .Changed:
            let translation = recognizer.translationInView(self)
            center = CGPoint(x: originalCenter.x + translation.x, y: originalCenter.y)
            let fractionOfThreshold = min(1, Double(abs(frame.origin.x) / (frame.size.width / 4)))
            releaseAction = fractionOfThreshold >= 1 ? (frame.origin.x > 0 ? .Complete : .Delete) : nil

            if !item.completed {
                backgroundOverlayView.backgroundColor = .completeGreenBackgroundColor()
                backgroundOverlayView.hidden = releaseAction != .Complete
                if frame.origin.x > 0 {
                    textView.unstrike()
                    textView.strike(fractionOfThreshold)
                } else {
                    releaseAction == .Complete ? textView.strike() : textView.unstrike()
                }
            } else {
                backgroundOverlayView.hidden = releaseAction == .Complete
                textView.alpha = releaseAction == .Complete ? 1 : 0.3
                if frame.origin.x > 0 {
                    textView.unstrike()
                    textView.strike(1 - fractionOfThreshold)
                } else {
                    releaseAction == .Complete ? textView.unstrike() : textView.strike()
                }
            }
            break
        case .Ended:
            switch releaseAction {
            case .Some(.Complete):
                setCompleted(!item.completed, animated: true)
                break
            case .Some(.Delete):
                delegate?.itemDeleted(item)
                break
            case nil:
                item.completed ? textView.strike() : textView.unstrike()
                break
            }
            let originalFrame = CGRect(x: 0, y: frame.origin.y, width: bounds.size.width, height: bounds.size.height)
            UIView.animateWithDuration(0.2) { [unowned self] in self.frame = originalFrame }
            break
        default:
            break
        }
    }

    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {

        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let translation = panGestureRecognizer.translationInView(superview!)
        return fabs(translation.x) > fabs(translation.y)
    }

    // MARK: Actions

    private func setCompleted(completed: Bool, animated: Bool = false) {
        item.completed = completed
        completed ? textView.strike() : textView.unstrike()
        backgroundOverlayView.hidden = !completed
        let updateColor = { [unowned self] in
            self.backgroundOverlayView.backgroundColor = completed ?
                .completeDimBackgroundColor() : .completeGreenBackgroundColor()
            self.textView.alpha = completed ? 0.3 : 1
        }
        if animated {
            if isDevice {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            UIView.animateWithDuration(0.2, animations: updateColor)
            if completed {
                delegate?.itemCompleted(item)
            }
        } else {
            updateColor()
        }
    }

    // MARK: UITextViewDelegate methods

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        // disable editing of completed to-do items
        return !item.completed
    }

    func textViewDidBeginEditing(textView: UITextView) {
        // TODO: dim other cells
    }

    func textViewDidEndEditing(textView: UITextView) {
        // TODO: undim other cells
        item.text = textView.text
    }

    // MARK: Unimplemented

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
