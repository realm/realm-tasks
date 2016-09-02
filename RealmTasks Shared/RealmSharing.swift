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

import Foundation
import RealmSwift

class RealmSharing {

    static func URLForGeneratedAccessFile(taskList: TaskList, token: String) -> NSURL {

        //Convert list to JSON
        let payload = NSMutableDictionary()
        payload["name"] = taskList.text
        payload["token"] = token

        let data = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])

        let fileName = "\(taskList.text)\(Constants.fileExtension)"
        let tempURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = tempURL.URLByAppendingPathComponent(fileName)

        try! data.writeToURL(fileURL, options: [])

        return fileURL
    }

    static func taskListForAccessFile(URL: NSURL) -> (name: String?, token: String?)? {
        if NSFileManager.defaultManager().fileExistsAtPath(URL.path!) == false {
            return nil
        }

        let data = NSData(contentsOfURL: URL)
        let jsonDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: [])

        return (name: String(jsonDictionary["name"]), token: String(jsonDictionary["token"]))
    }
}
