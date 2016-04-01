//
//  NSURL+Kakapo.swift
//  KakapoExample
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

func checkUrl(handlerUrl: String, requestUrl: String) -> [String : String]? {
    let paths = splitUrl(handlerUrl, withSeparator: ":")
    var requestParams: [String : String] = [:]
    var changableUrl = requestUrl
    
    for (index, path) in paths.enumerate() {
        if changableUrl.rangeOfString(path) == nil {
            return nil
        }
        changableUrl = replaceUrl(changableUrl, find: path, with: "")
        let nextPaths = splitUrl(changableUrl, withSeparator: "/")
        
        if let next = nextPaths.first {
            if let key = splitUrl(paths[index + 1], withSeparator: "/").first {
                changableUrl = replaceUrl(changableUrl, find: next, with: key)
                requestParams[key] = next
            }
        }
    }
    
    return requestParams
}

func splitUrl(url: String, withSeparator separator: Character) -> [String] {
    return url.characters.split(separator).map{ String($0) }
}

func replaceUrl(source: String, find: String, with: String) -> String {
    return source.stringByReplacingOccurrencesOfString(find, withString: with)
}

    