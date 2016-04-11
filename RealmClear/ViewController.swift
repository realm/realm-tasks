//
//  ViewController.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Cartography
import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        setupTableView()
    }

    func setupTableView() {
        view.addSubview(tableView)
        constrain(tableView) { tableView in
            tableView.edges == tableView.superview!.edges
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .None
        tableView.backgroundColor = .blackColor()
        tableView.rowHeight = 54
        tableView.contentInset = UIEdgeInsets(top: 45, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
        tableView.showsVerticalScrollIndicator = false
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
    }
}
