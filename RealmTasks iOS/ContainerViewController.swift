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

import Cartography
import RealmSwift
import UIKit

class ContainerViewController: UIViewController {
    private var titleBar = UIToolbar()
    private var titleLabel = UILabel()
    private var titleTopConstraint: NSLayoutConstraint?
    override var title: String? {
        didSet {
            if let title = title {
                titleLabel.text = title
            }
            titleTopConstraint?.constant = (title != nil) ? 20 : 0
            UIView.animateWithDuration(0.2) {
                self.titleLabel.alpha = (self.title != nil) ? 1 : 0
                self.titleLabel.superview?.layoutIfNeeded()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChildVC(try! Realm().objects(TaskList.self).first!)
        setupTitleBar()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    func transitionToList(taskList: TaskList, animated: Bool) {
        let viewControllers = self.childViewControllers
        var snapshotView: UIView? = nil

        if animated {
            snapshotView = self.view.snapshotViewAfterScreenUpdates(false)
            self.view.addSubview(snapshotView!)
        }

        for controller in viewControllers {
            controller.removeFromParentViewController()
            controller.view.removeFromSuperview()
        }

        addChildVC(taskList)

        if animated {
            self.view.bringSubviewToFront(titleBar)
            self.view.insertSubview(snapshotView!, belowSubview: titleBar)

            UIView.animateWithDuration(0.3, animations: {
                snapshotView?.alpha = 0.0
            }, completion: { (complete) in
                snapshotView?.removeFromSuperview()
            })
        }
    }

    private func addChildVC(taskList: TaskList) {
        let firstList = try! Realm().objects(TaskListReference.self).first!.list
        let vc = ViewController(parent: firstList, colors: UIColor.taskColors())
        title = firstList.text
        addChildViewController(vc)
        view.addSubview(vc.view)
        vc.didMoveToParentViewController(self)
    }

    private func setupTitleBar() {
        titleBar.barStyle = .BlackTranslucent
        view.addSubview(titleBar)
        constrain(titleBar) { titleBar in
            titleBar.left == titleBar.superview!.left
            titleBar.top == titleBar.superview!.top
            titleBar.right == titleBar.superview!.right
            titleBar.height >= 20
            titleBar.height == 20 ~ UILayoutPriorityDefaultHigh
        }

        titleLabel.font = .boldSystemFontOfSize(13)
        titleLabel.textAlignment = .Center
        titleLabel.textColor = .whiteColor()
        titleBar.addSubview(titleLabel)
        constrain(titleLabel) { titleLabel in
            titleLabel.left == titleLabel.superview!.left
            titleLabel.right == titleLabel.superview!.right
            titleLabel.bottom == titleLabel.superview!.bottom - 5
            titleTopConstraint = (titleLabel.top == titleLabel.superview!.top + 20)
        }
    }
}
