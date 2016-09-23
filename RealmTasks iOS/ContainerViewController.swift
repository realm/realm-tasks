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

enum NavDirection {
  case Up, Down
}

//MARK: Container View Controller Protocol
enum Position {
    case Up
}

protocol ContainerNavigationProtocol {
    func isTopChild(position: NavDirection) -> Bool
    
    func auxViewController(position: NavDirection) -> UIViewController?
    func setAuxViewController(position: NavDirection, _ viewController: UIViewController?)
    func createAuxViewController(position: NavDirection) -> (() -> (UIViewController))?
    func setCreateAuxViewController(position: NavDirection, _ handler: (() -> (UIViewController))?)

    func canCreateViewControllerAt(position: NavDirection) -> Bool
    func removeViewControllerAt(position: NavDirection)
}

//MARK: Container View Controller

class ContainerViewController: UIViewController, ContainerNavigationProtocol {
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
        addChildVC()
        setupTitleBar()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    private func addChildVC() {
        let firstList = try! Realm().objects(TaskList.self).first!
        let vc = ViewController(navigation: self, parent: firstList, colors: UIColor.taskColors())
        title = firstList.text
        addChildViewController(vc)
        view.addSubview(vc.view)
        vc.didMoveToParentViewController(self)
    }

    private func setupTitleBar() {
        let titleBar = UIToolbar()
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

    var topChildViewController: ViewControllerProtocol {
        return childViewControllers.last as! ViewControllerProtocol
    }

    private var nextConstraints: ConstraintGroup?

    // Top/Bottom View Controllers
    // MARK: ContainerNavigationProtocol methods
    private var createTopViewController: (() -> (UIViewController))?
    private var topViewController: UIViewController?
    private var createBottomViewController: (() -> (UIViewController))?
    private var bottomViewController: UIViewController?

    func isTopChild(position: NavDirection) -> Bool {
        return topChildViewController === auxViewController(position)
    }

    func auxViewController(position: NavDirection) -> UIViewController? {
        return (position == .Up) ? topViewController : bottomViewController
    }

    func setAuxViewController(position: NavDirection, _ viewController: UIViewController?) {
        if position == .Up {
            topViewController = viewController
        } else {
            bottomViewController = viewController
        }
    }

    func createAuxViewController(position: NavDirection) -> (() -> (UIViewController))? {
        return (position == .Up) ? createTopViewController : createBottomViewController
    }

    func setCreateAuxViewController(position: NavDirection, _ handler: (() -> (UIViewController))?) {
        if position == .Up {
            createTopViewController = handler
        } else {
            createBottomViewController = handler
        }
    }

    func canCreateViewControllerAt(position: NavDirection) -> Bool {
        print("can create vc at \(position)")
        return ((position == .Up) ? createTopViewController : createBottomViewController) != nil
    }

    func removeViewControllerAt(position: NavDirection) {
        if let viewController = auxViewController(position) {
            viewController.view.removeFromSuperview()
            viewController.removeFromParentViewController()
        }
    }

}
