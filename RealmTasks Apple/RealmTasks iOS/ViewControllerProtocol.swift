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

// MARK: View Controller Protocol

protocol ViewControllerProtocol: UIScrollViewDelegate {
    var tableView: UITableView {get}
    var tableViewContentView: UIView {get}
    var view: UIView! {get}

    func didUpdateList()

    func setTopConstraintTo(constant constant: CGFloat)
    func setPlaceholderAlpha(alpha: CGFloat)

    func setListTitle(title: String)

    func removeFromParentViewController()
}
