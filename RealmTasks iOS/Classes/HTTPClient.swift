//
//  HTTPClient.swift
//  RealmSyncAuth
//
//  Created by Dmitry Obukhov on 27/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

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
