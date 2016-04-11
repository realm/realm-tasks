//
//  ViewController.swift
//  RealmClear
//
//  Created by JP Simard on 4/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Cartography
import UIKit

var items =  [
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "Quisque at magna auctor, rhoncus massa sit amet, sodales felis.",
    "Suspendisse consequat purus at dolor ultricies interdum.",
    "In luctus magna aliquet, tincidunt ante et, aliquam tellus.",
    "Suspendisse suscipit lorem ac purus interdum, eu maximus ante pellentesque.",
    "Aenean elementum est ut eros varius posuere vel sit amet eros.",
    "Duis accumsan dolor quis leo tincidunt consectetur.",
    "Proin dictum felis non dui dapibus molestie.",
    "Fusce id est eget erat blandit rutrum.",
    "Fusce rutrum ipsum ac nisi euismod pellentesque.",
    "Nulla venenatis neque id eros consectetur, id pretium turpis sodales.",
    "Nulla in sem pharetra, hendrerit diam ac, mollis nisl.",
    "Nulla nec lectus sed massa tristique maximus.",
    "Cras aliquam velit luctus lacus accumsan, id fringilla eros commodo."
].map(ToDoItem.init)

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
        return items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = items[indexPath.row].text
        return cell
    }
}
