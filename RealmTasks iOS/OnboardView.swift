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

import Foundation
import Cartography
import UIKit

class OnboardView: UIView {
    private let contentColor = UIColor(white: 0.13, alpha: 1)
    private let contentPadding: CGFloat = 15

    private let imageView = UIImageView(image: UIImage(named: "PullToRefresh")?.imageWithRenderingMode(.AlwaysTemplate))
    private let labelView = UILabel()

    init() {
        labelView.text = "Pull Down to Start"
        labelView.font = .systemFontOfSize(20, weight: UIFontWeightMedium)
        labelView.textColor = contentColor
        labelView.textAlignment = .Center
        labelView.sizeToFit()

        imageView.tintColor = contentColor

        var frame = CGRect.zero
        frame.size.width = labelView.frame.size.width
        frame.size.height = imageView.frame.height + contentPadding + labelView.frame.height

        super.init(frame: frame)

        addSubview(imageView)
        addSubview(labelView)

        autoresizingMask = [.FlexibleBottomMargin, .FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleRightMargin]

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        constrain(labelView, imageView) { labelView, imageView in
            labelView.centerX == labelView.superview!.centerX
            labelView.bottom == labelView.superview!.bottom

            imageView.centerX == imageView.superview!.centerX
            imageView.top == imageView.superview!.top
        }
    }

    func toggle(animated animated: Bool = false, isVisible: Bool) {
        func updateAlpha() {
            alpha = isVisible ? 1 : 0
        }

        if animated {
            UIView.animateWithDuration(0.3, animations: updateAlpha)
        } else {
            updateAlpha()
        }
    }
    

}
