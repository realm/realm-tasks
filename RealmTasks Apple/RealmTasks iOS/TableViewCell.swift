////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

// FIXME: This file should be split up.
// swiftlint:disable file_length

import AudioToolbox
import Cartography
import RealmSwift
import UIKit

// MARK: Shared Functions

func vibrate() {
    let isDevice = { return TARGET_OS_SIMULATOR == 0 }()
    if isDevice {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

// MARK: Private Declarations

private enum ReleaseAction {
    case Complete, Delete
}

private let iconWidth: CGFloat = 60

// MARK: Table View Cell

// FIXME: This class should be split up.
// swiftlint:disable type_body_length
final class TableViewCell<Item: Object where Item: CellPresentable>: UITableViewCell, UITextViewDelegate {

    // MARK: Properties

    // Stored Properties
    let textView = CellTextView()
    var item: Item! {
        didSet {
            textView.text = item.text
            setCompleted(item.completed)
            if let item = item as? TaskList {
                let count = item.items.filter("completed == false").count
                countLabel.text = String(count)
                if count == 0 {
                    textView.alpha = 0.3
                    countLabel.alpha = 0.3
                } else {
                    countLabel.alpha = 1
                }
            }
        }
    }
    let navHintView = NavHintView()

    // Callbacks
    var presenter: CellPresenter<Item>!

    // Private Properties
    private var originalDoneIconCenter = CGPoint()
    private var originalDeleteIconCenter = CGPoint()

    private var releaseAction: ReleaseAction?
    private let overlayView = UIView()
    private let countLabel = UILabel()

    // Assets
    private let doneIconView = UIImageView(image: UIImage(named: "DoneIcon"))
    private let deleteIconView = UIImageView(image: UIImage(named: "DeleteIcon"))

    // MARK: Initializers

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None

        setupUI()
        setupPanGestureRecognizer()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UI

    private func setupUI() {
        setupBackgroundView()
        setupIconViews()
        setupOverlayView()
        setupTextView()
        setupBorders()
        if Item.self == TaskList.self {
            setupCountBadge()
        }
        setupNavHintView()
    }

    func reset() {
        presenter = nil
    }

    private func setupBackgroundView() {
        backgroundColor = .clearColor()

        backgroundView = UIView()
        constrain(backgroundView!) { backgroundView in
            backgroundView.edges == backgroundView.superview!.edges
        }
    }

    private func setupIconViews() {
        doneIconView.center = center
        doneIconView.frame.origin.x = 20
        doneIconView.alpha = 0
        doneIconView.autoresizingMask = [.FlexibleRightMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
        insertSubview(doneIconView, belowSubview: contentView)

        deleteIconView.center = center
        deleteIconView.frame.origin.x = bounds.width - deleteIconView.bounds.width - 20
        deleteIconView.alpha = 0
        deleteIconView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
        insertSubview(deleteIconView, belowSubview: contentView)
    }

    private func setupOverlayView() {
        overlayView.backgroundColor = .completeDimBackgroundColor()
        overlayView.hidden = true
        contentView.addSubview(overlayView)
        constrain(overlayView) { backgroundOverlayView in
            backgroundOverlayView.edges == backgroundOverlayView.superview!.edges
        }
    }

    private func setupTextView() {
        textView.delegate = self
        contentView.addSubview(textView)
        constrain(textView) { textView in
            textView.left == textView.superview!.left + 8
            textView.top == textView.superview!.top + 8
            textView.bottom == textView.superview!.bottom - 8
            if Item.self == TaskList.self {
                textView.right == textView.superview!.right - 68
            } else {
                textView.right == textView.superview!.right - 8
            }
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

    private func setupCountBadge() {
        let badgeBackground = UIView()
        badgeBackground.backgroundColor = UIColor(white: 1, alpha: 0.15)
        contentView.addSubview(badgeBackground)
        constrain(badgeBackground) { badgeBackground in
            badgeBackground.top == badgeBackground.superview!.top
            badgeBackground.bottom == badgeBackground.superview!.bottom
            badgeBackground.right == badgeBackground.superview!.right
            badgeBackground.width == 60
        }

        badgeBackground.addSubview(countLabel)
        countLabel.backgroundColor = .clearColor()
        countLabel.textColor = .whiteColor()
        countLabel.font = .systemFontOfSize(18)
        constrain(countLabel) { countLabel in
            countLabel.center == countLabel.superview!.center
        }
    }

    private func setupNavHintView() {
        navHintView.alpha = 0
        contentView.addSubview(navHintView)
        constrain(navHintView) { navHintView in
            navHintView.edges == navHintView.superview!.edges
        }
    }

    // MARK: Pan Gesture Recognizer

    private func setupPanGestureRecognizer() {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }

    func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .Began: handlePanBegan()
        case .Changed: handlePanChanged(translation: recognizer.translationInView(self).x)
        case .Ended: handlePanEnded()
        default:
            break
        }
    }

    private func handlePanBegan() {
        originalDeleteIconCenter = deleteIconView.center
        originalDoneIconCenter = doneIconView.center

        releaseAction = nil
    }

    private func handlePanChanged(translation translation: CGFloat) {
        if !item.isCompletable && translation > 0 {
            releaseAction = nil
            return
        }

        let x: CGFloat
        // Slow down translation
        if translation < 0 {
            x = translation / 2
            if x < -iconWidth {
                deleteIconView.center = CGPoint(x: originalDeleteIconCenter.x + iconWidth + x, y: originalDeleteIconCenter.y)
            }
        } else if translation > iconWidth {
            let offset = (translation - iconWidth) / 3
            doneIconView.center = CGPoint(x: originalDoneIconCenter.x + offset, y: originalDoneIconCenter.y)
            x = iconWidth + offset
        } else {
            x = translation
        }

        contentView.frame.origin.x = x

        let fractionOfThreshold = min(1, Double(abs(x) / iconWidth))
        releaseAction = fractionOfThreshold >= 1 ? (x > 0 ? .Complete : .Delete) : nil

        if x > 0 {
            doneIconView.alpha = CGFloat(fractionOfThreshold)
        } else {
            deleteIconView.alpha = CGFloat(fractionOfThreshold)
        }

        if !(item as Object).invalidated && !item.completed {
            overlayView.backgroundColor = .completeGreenBackgroundColor()
            overlayView.hidden = releaseAction != .Complete
            if contentView.frame.origin.x > 0 {
                textView.unstrike()
                textView.strike(fractionOfThreshold)
            } else {
                releaseAction == .Complete ? textView.strike() : textView.unstrike()
            }
        } else {
            overlayView.hidden = releaseAction == .Complete
            textView.alpha = releaseAction == .Complete ? 1 : 0.3
            if contentView.frame.origin.x > 0 {
                textView.unstrike()
                textView.strike(1 - fractionOfThreshold)
            } else {
                releaseAction == .Complete ? textView.unstrike() : textView.strike()
            }
        }
    }

    private func handlePanEnded() {
        guard item != nil && !(item as Object).invalidated else {
            return
        }
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
                self.setCompleted(!self.item.completed, animated: true)
            }
        case .Delete?:
            animationBlock = {
                self.alpha = 0
                self.contentView.alpha = 0

                self.contentView.frame.origin.x = -self.contentView.bounds.width - iconWidth
                self.deleteIconView.frame.origin.x = -iconWidth + self.deleteIconView.bounds.width + 20
            }
            completionBlock = {
                self.presenter.deleteItem(self.item)
            }
        case nil:
            item.completed ? textView.strike() : textView.unstrike()
            animationBlock = {
                self.contentView.frame.origin.x = 0
            }
            completionBlock = {}
        }

        UIView.animateWithDuration(0.2, animations: animationBlock) { _ in
            if self.item != nil && !(self.item as Object).invalidated {
                completionBlock()
            }

            self.doneIconView.frame.origin.x = 20
            self.doneIconView.alpha = 0

            self.deleteIconView.frame.origin.x = self.bounds.width - self.deleteIconView.bounds.width - 20
            self.deleteIconView.alpha = 0
        }
    }

    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let translation = panGestureRecognizer.translationInView(superview!)
        return fabs(translation.x) > fabs(translation.y)
    }

    // MARK: Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        alpha = 1
        contentView.alpha = 1
        textView.unstrike()

        // Force any active gesture recognizers to reset
        for gestureRecognizer in gestureRecognizers! {
            gestureRecognizer.reset()
        }
    }

    // MARK: Actions

    private func setCompleted(completed: Bool, animated: Bool = false) {
        completed ? textView.strike() : textView.unstrike()
        overlayView.hidden = !completed
        let updateColor = { [unowned self] in
            self.overlayView.backgroundColor = completed ?
                .completeDimBackgroundColor() : .completeGreenBackgroundColor()
            self.textView.alpha = completed ? 0.3 : 1
        }
        if animated {
            try! item.realm?.write {
                item.completed = completed
            }
            vibrate()
            UIView.animateWithDuration(0.2, animations: updateColor)
            presenter.completeItem(item)
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
        presenter.cellDidBeginEditing(self)
    }

    func textViewDidEndEditing(textView: UITextView) {
        item.text = textView.text.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
        textView.userInteractionEnabled = false
        presenter.cellDidEndEditing(self)
    }

    func textViewDidChange(textView: UITextView) {
        presenter.cellDidChangeText(self)
    }
}

// Mark: Gesture Recognizer Reset

extension UIGestureRecognizer {
    private func reset() {
        enabled = false
        enabled = true
    }
}
