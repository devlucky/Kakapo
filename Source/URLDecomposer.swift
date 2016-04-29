//
//  URLDecomposer.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 A tuple holding components and query parameters, check `decomposeURL` for more details
 */
public typealias URLInfo = (components: [String : String], queryParameters: [NSURLQueryItem])

/**
 Checks and parses if a given `handleURL` representation matches a `requestURL`. Examples:
 
 `/users/:id` with `/users/1` produces `components: ["id" : "1"]`
 `/users/:id/comments` with `/users/1/comments` produces `components: ["id" : "1"]`
 `/users/:id/comments/:comment_id` with `/users/1/comments/2?page=2&author=hector` produces `components: ["id": "1", "comment_id": "2"]` and `queryParameters: ["page": "2", "author": "hector"]`
 
 - parameter handlerPath: the URL handler with dynamic paths
 - parameter requestURLComponents: the components of the actual URL
 
 - returns: a URL info object containing `components` and `queryParamaters`
 */
func decomposeURL(handlerPath: String, requestURLComponents: NSURLComponents) -> URLInfo? {
    var components: [String : String] = [:]
    let handlerSplittedPaths = splitUrl(handlerPath, withSeparator: ":")
    
    guard var requestURLPath = requestURLComponents.path where
        splitUrl(handlerPath, withSeparator: "/").count == splitUrl(requestURLPath, withSeparator: "/").count else {
        return nil
    }
    
    for (index, path) in handlerSplittedPaths.enumerate() {
        guard requestURLPath.rangeOfString(path) != nil else {
            return nil
        }
        
        requestURLPath = replaceUrl(requestURLPath, find: path, with: "")
        let nextPaths = splitUrl(requestURLPath, withSeparator: "/")
        
        if let next = nextPaths.first {
            if let key = splitUrl(handlerSplittedPaths[index + 1], withSeparator: "/").first {
                requestURLPath = replaceUrl(requestURLPath, find: next, with: key)
                components[key] = next
            }
        }
    }
    
    return (components, requestURLComponents.queryItems ?? [])
}

private func splitUrl(url: String, withSeparator separator: Character) -> [String] {
    return url.characters.split(separator).map{ String($0) }
}

private func replaceUrl(source: String, find: String, with: String) -> String {
    return source.stringByReplacingOccurrencesOfString(find, withString: with)
}

    