//
//  NavHintView.swift
//  RealmTasks
//
//  Created by Tim Oliver on 11/08/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit
import Cartography

class NavHintView: UIView {

    var hintText: String? {
        set {
            textLabel.text = newValue
            textLabel.sizeToFit()
            self.layoutIfNeeded()
        }
        get {
            return textLabel.text
        }
    }

    var hintImage = UIImage(named: "SwitchListArrow")

    let textLabel = UILabel()
    let hintImageView = UIImageView()

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
