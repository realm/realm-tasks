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
