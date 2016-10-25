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
