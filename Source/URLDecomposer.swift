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
 Parses and checks if a given `handlerPath` representation matches a `requestURLComponents`. Examples:
 
 `/users/:id` with `/users/1` produces `components: ["id" : "1"]`
 `/users/:id/comments` with `/users/1/comments` produces `components: ["id" : "1"]`
 `/users/:id/comments/:comment_id` with `/users/1/comments/2?page=2&author=hector` produces `components: ["id": "1", "comment_id": "2"]` and `queryParameters: ["page": "2", "author": "hector"]`
 
 - parameter handlerPath: the URL handler with dynamic paths
 - parameter requestURLComponents: the components of the actual URL
 
 - returns: a URL info object containing `components` and `queryParamaters`
 */

/**
 <#Description#>
 
 - parameter baseURL:     The base URL (e.g. devlucky.com or https://devlucky.com)
 - parameter handlerPath: The URL path (e.g. /api/v2/sessions or with parameters /api/v2/user/:userid )
 - parameter requestURL:  The URL of the request
 
 - returns: A URL info object containing `components` and `queryParamaters` or nil if `requestURL`doesn't match the route.
 */
func decomposeURL(base baseURL: String, path: String, requestURL: NSURL) -> URLInfo? { // TODO: docu and test scheme
    
    // TODO: test when relevantURLLocation is last index
    
    // remove the baseURL and the params, if baseURL is not in the string the result will be nil
    guard let relevantURL: String = {
        let string = requestURL.absoluteString
        let stringWithoutParams = string.substring(.To, string: "?") ?? string // remove params if present
        return stringWithoutParams.substring(.From, string: baseURL)
        }() else { return nil }
    
    let routePathComponents = path.split("/") // e.g. [api, :userid]
    let requestPathComponents = relevantURL.split("/") // e.g. api, 1234]

    guard routePathComponents.count == requestPathComponents.count else {
        // different components count means that the path can't match
        return nil
    }
    
    var components: [String : String] = [:]

    for (routeComponent, requestComponent) in zip(routePathComponents, requestPathComponents) {
        // [api, :userid] [api, 1234]
        
        // if they are not equal then it must be a key prefixed by ":" otherwise the route is not matched
        let firstChar: Character = routeComponent.characters.first ?? Character("")
        
        if routeComponent == requestComponent {
            continue // not a component
        } else {
            guard firstChar == ":" else {
                return nil // not equal nor a key
            }
        }
        
        let relevantKeyIndex = routeComponent.characters.startIndex.successor() // second position
        let key = routeComponent.substringFromIndex(relevantKeyIndex) // :key -> key
        components[key] = requestComponent
    }

    
    let queryItems = NSURLComponents(URL: requestURL, resolvingAgainstBaseURL: false)?.queryItems

    return (components, queryItems ?? [])
}

private extension String {
    func split(separator: Character) -> [String] {
        return characters.split(separator).map { String($0) }
    }
    
    enum SplitMode {
        case From
        case To
    }
    
    func substring(mode: SplitMode, string: String) -> String? {
        guard string.characters.count > 0 else {
            return self
        }
        
        guard let range = rangeOfString(string) else {
            return nil
        }
        
        switch mode {
        case .From:
            return substringFromIndex(range.endIndex)
        case .To:
            return substringToIndex(range.startIndex)
        }
    }
}


    