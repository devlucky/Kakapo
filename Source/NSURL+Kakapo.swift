//
//  NSURL+Kakapo.swift
//  KakapoExample
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/// checkUrl does sdasdasds
/// - Parameter term: whatever
/// - Parameter term: whatever
/// - Returns: term
func checkUrl(handlerUrl: String, requestUrl: String) -> (params: [String : String], queryParams: [String : String])? {
    let paths = splitUrl(handlerUrl, withSeparator: ":")
    var params: [String : String] = [:]
    var queryParams: [String : String] = [:]
    var changableUrl = splitUrl(requestUrl, withSeparator: "?")
    var paramsUrl = changableUrl[0]
    
    for (index, path) in paths.enumerate() {
        if paramsUrl.rangeOfString(path) == nil {
            return nil
        }
        paramsUrl = replaceUrl(paramsUrl, find: path, with: "")
        let nextPaths = splitUrl(paramsUrl, withSeparator: "/")
        
        if let next = nextPaths.first {
            if let key = splitUrl(paths[index + 1], withSeparator: "/").first {
                paramsUrl = replaceUrl(paramsUrl, find: next, with: key)
                params[key] = next
            }
        }
    }
    if changableUrl.count > 1 {
        let queryParamsUrl = splitUrl(changableUrl[1], withSeparator: "&")
        for param in queryParamsUrl {
            let values = splitUrl(param, withSeparator: "=")
            queryParams[values[0]] = values[1]
        }
    }
    
    return (params, queryParams)
}

func splitUrl(url: String, withSeparator separator: Character) -> [String] {
    return url.characters.split(separator).map{ String($0) }
}

func replaceUrl(source: String, find: String, with: String) -> String {
    return source.stringByReplacingOccurrencesOfString(find, withString: with)
}

    