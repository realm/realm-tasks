////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import RealmSwift

class SharingCoordinator {

    private weak var viewController: UIViewController?
    private var shareOfferNotificationToken: NotificationToken?
    private var shareReceivedNotificationToken: NotificationToken?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    deinit {
        shareOfferNotificationToken?.stop()
    }

    public func shareList(for realm: Realm, from view: UIView?) {
        let realmURL = realm.configuration.syncConfiguration!.realmURL
        let managementRealm = try! SyncUser.current!.managementRealm()

        // Create offer with full permissions
        let shareOffer = SyncPermissionOffer(realmURL: realmURL.absoluteString, expiresAt: nil,
                                             mayRead: true, mayWrite: true, mayManage: false)
        // Add to management Realm to sync with ROS
        try! managementRealm.write {
            managementRealm.add(shareOffer)
        }

        // Wait for server to process
        let offerResults = managementRealm.objects(SyncPermissionOffer.self).filter("id = %@", shareOffer.id)
        shareOfferNotificationToken = offerResults.addNotificationBlock { _ in
            guard case let offer = offerResults.first, offer?.status == .success, let token = offer?.token else {
                    return
            }
            // Send token via UIActivityViewController
            let url = URL(string: "realmtasks://" + token.replacingOccurrences(of: ":", with: "/"))!
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityViewController.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            if let view = view {
                activityViewController.popoverPresentationController?.sourceView = view
            }
            self.viewController?.present(activityViewController, animated: true, completion: nil)
        }
    }
}
