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

class HTTPClient {

    static func post(url: NSURL, json: AnyObject, completion: ((NSData?, NSHTTPURLResponse?, NSError?) -> Void)?) throws -> NSURLSessionTask {

        let data = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)

        return post(url, data: data, completion: completion)
    }

    static func post(url: NSURL, data: NSData?, completion: ((NSData?, NSHTTPURLResponse?, NSError?) -> Void)?) -> NSURLSessionTask {
        let request = NSMutableURLRequest(URL: url)

        request.addValue("application/json;charset=utf-8", forHTTPHeaderField:"Content-Type")
        request.addValue("application/json", forHTTPHeaderField:"Accept")

        request.HTTPMethod = "POST"
        request.HTTPBody = data

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            dispatch_async(dispatch_get_main_queue()) {
                completion?(data, response as? NSHTTPURLResponse, error)
            }
        }

        task.resume()

        return task
    }

}
