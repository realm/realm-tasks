//
//  ShareInteractor.swift
//  RealmTasks
//
//  Created by Marin Todorov on 9/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

protocol ListPresenterProtocol {
    func shareListUrl(urlString: String)
    func moveCell(from from: NSIndexPath, to: NSIndexPath)
    func deleteCell(from from: [NSIndexPath], withRowAnimation: UITableViewRowAnimation)
}

class ShareInteractor {
    var presenter: ListPresenterProtocol!

    func share(taskList: TaskList) {
        let id = taskList.realm?.configuration.syncConfiguration?.realmURL.lastPathComponent

        let shareOffer = ShareOffer()
        let realm = try! Realm()
        shareOffer.listName = taskList.text
        shareOffer.listPath = "/\(realm.configuration.syncConfiguration!.user.identity)/\(id!)"

        try! realm.write {
            realm.add(shareOffer)
        }

        presenter.shareListUrl(shareOffer.url)
    }

}