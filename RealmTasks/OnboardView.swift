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

class OnboardView: UIView
{
    let contentColor = UIColor(white: 0.13, alpha: 1.0)
    let contentPadding = 15.0

    let imageView = UIImageView(image: UIImage(named: "PullToRefresh")?.imageWithRenderingMode(.AlwaysTemplate))
    let labelView = UILabel()

    init() {
        labelView.text = "Pull Down to Start"
        labelView.font = UIFont.systemFontOfSize(20, weight: UIFontWeightMedium)
        labelView.textColor = contentColor
        labelView.textAlignment = .Center
        labelView.sizeToFit()

        imageView.tintColor = contentColor

        var frame = CGRectZero
        frame.size.width = labelView.frame.size.width
        frame.size.height = CGRectGetHeight(imageView.frame) + CGFloat(contentPadding) + CGRectGetHeight(labelView.frame)

        super.init(frame: frame)

        self.addSubview(imageView)
        self.addSubview(labelView)

        self.autoresizingMask = [.FlexibleBottomMargin, .FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleRightMargin]

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        constrain(labelView, imageView) { labelView, imageView in
            labelView.centerX == labelView.superview!.centerX
            labelView.bottom == labelView.superview!.bottom

            imageView.centerX == imageView.superview!.centerX
            imageView.top == imageView.superview!.top
        }
    }
}