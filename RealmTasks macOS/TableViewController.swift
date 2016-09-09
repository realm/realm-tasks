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

import Cocoa
import Cartography

class TableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet var tableView: NSTableView!

    override func loadView() {
        view = NSView()
        view.wantsLayer = true

        tableView = NSTableView()
        tableView.addTableColumn(NSTableColumn())
        tableView.backgroundColor = .blackColor()
        tableView.headerView = nil
        tableView.selectionHighlightStyle = .None
        tableView.intercellSpacing = .zero

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.backgroundColor = .blackColor()

        view.addSubview(scrollView)

        constrain(scrollView) { scrollView in
            scrollView.edges == scrollView.superview!.edges
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.setDelegate(self)
        tableView.setDataSource(self)
    }
    
}
