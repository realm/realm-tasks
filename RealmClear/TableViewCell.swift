//
//  TableViewCell.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Cartography
import UIKit

enum ReleaseAction {
    case Complete, Delete
}

class TableViewCell: UITableViewCell {
    var item: ToDoItem! {
        didSet {
            textView.text = item?.text
        }
    }
    let textView = ToDoItemTextView()
    var originalCenter = CGPoint()
    var releaseAction: ReleaseAction?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None

        setupUI()
        setupPanGestureRecognizer()
    }

    // MARK: UI

    func setupUI() {
        setupTextView()
        setupBorders()
    }

    func setupTextView() {
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
            let exceedsThreshold = fabs(frame.origin.x) > frame.size.width / 4
            releaseAction = exceedsThreshold ? (frame.origin.x > 0 ? .Complete : .Delete) : nil
            // TODO: update UI to reflect release action
            break
        case .Ended:
            switch releaseAction {
            case .Some(.Complete):
                // TODO: mark item as completed
                break
            case .Some(.Delete):
                // TODO: delete item
                break
            case nil:
                // TODO: reset state
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

    // MARK: Unimplemented

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
