//
//  ViewController.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Cartography
import UIKit

class ViewController: UIViewController {
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
    }
}
