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

class ShareButtonView: UIView {

    private let shareButton = UIButton(type: .System)

    var buttonTappedHandler: (() -> ())?

    init() {
        super.init(frame: CGRectMake(0,0,320,44))
        self.backgroundColor = .blackColor()
        self.tintColor = UIColor(white: 0.3, alpha: 1.0)
        setupButton()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupButton() {
        let image = UIImage(named: "ShareIcon")?.imageWithRenderingMode(.AlwaysTemplate)
        shareButton.setImage(image, forState: .Normal)
        shareButton.setTitle("Share List", forState: .Normal)
        shareButton.titleLabel!.font = UIFont.systemFontOfSize(18.0)
        shareButton.addTarget(self, action: #selector(self.buttonTapped), forControlEvents: .TouchUpInside)
        shareButton.sizeToFit()
        shareButton.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, -6)
        shareButton.imageEdgeInsets = UIEdgeInsetsMake(-2, 0, 2, 0)

        addSubview(shareButton)

        constrain(shareButton) { shareButton in
            shareButton.center == shareButton.superview!.center
        }
    }

    func buttonTapped(sender: AnyObject?) {
        if let buttonTappedHandler = buttonTappedHandler {
            buttonTappedHandler()
        }
    }
}
