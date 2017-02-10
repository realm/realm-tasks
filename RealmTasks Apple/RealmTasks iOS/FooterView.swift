//
//  FooterView.swift
//  RealmTasks
//
//  Created by Tim Oliver on 2/9/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import UIKit
import Cartography

class FooterView: UIView {
    public var shareButtonTapped: (() -> Void)?

    private let shareButton = UIButton(type: .system)

    override init(frame: CGRect) {
        var newFrame = frame
        newFrame.size.height = 64
        super.init(frame: newFrame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpButton() {
        guard shareButton.superview == nil else { return }

        shareButton.setImage(UIImage.shareIcon(), for: .normal)
        shareButton.setTitle("Share List", for: .normal)
        shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 25, weight: UIFontWeightMedium)
        shareButton.tintColor = UIColor(white: 0.3, alpha: 1.0)
        shareButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        shareButton.titleEdgeInsets = UIEdgeInsets(top: 3, left: 10, bottom: 0, right: 0)
        shareButton.sizeToFit()
        self.addSubview(shareButton)

        constrain(shareButton) { view in
            view.width == 220
            view.center == view.superview!.center
        }

        shareButton.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        frame.size.height = 60
        setUpButton()
    }

    @objc private func buttonTapped(sender _: AnyObject?) {
        shareButtonTapped?()
    }
}
