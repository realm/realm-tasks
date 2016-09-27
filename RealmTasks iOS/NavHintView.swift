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

import UIKit
import Cartography

class NavHintView: UIView {

    var hintText: String? {
        set {
            textLabel.text = newValue
        }
        get {
            return textLabel.text
        }
    }

    private let hintImage = UIImage(named: "SwitchListArrow")

    var hintArrowTransfom: CGAffineTransform {
        set {
            hintImageView.transform = newValue
        }
        get {
            return hintImageView.transform
        }
    }

    private let textLabel = UILabel()
    private let hintImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .blackColor()
        setUpLabelAndIcon()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLabelAndIcon() {
        hintImageView.image = hintImage
        hintImageView.sizeToFit()
        addSubview(hintImageView)

        textLabel.backgroundColor = .blackColor()
        textLabel.textColor = .whiteColor()
        textLabel.font = .systemFontOfSize(18)
        textLabel.textAlignment = .Center
        addSubview(textLabel)

        constrain(textLabel, hintImageView) { textLabel, hintImageView in
            textLabel.center == textLabel.superview!.center
            hintImageView.centerY == hintImageView.superview!.centerY
            hintImageView.right == textLabel.left - 10
        }
    }

}
