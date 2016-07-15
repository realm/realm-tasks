//
//  OnboardView.swift
//  RealmClear
//
//  Created by Tim Oliver on 15/07/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

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