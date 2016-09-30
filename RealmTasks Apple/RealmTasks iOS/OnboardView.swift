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

import Foundation
import Cartography
import UIKit

class OnboardView: UIView {
    private let contentColor = UIColor(white: 0.13, alpha: 1)
    private let contentPadding: CGFloat = 15

    private let imageView = UIImageView(image: UIImage(named: "PullToRefresh")?.imageWithRenderingMode(.AlwaysTemplate))
    private let labelView = UILabel()

    static func add(inView tableView: UITableView) -> OnboardView {
        let onBoard = OnboardView()
        tableView.addSubview(onBoard)
        onBoard.center = tableView.center
        return onBoard
    }

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
