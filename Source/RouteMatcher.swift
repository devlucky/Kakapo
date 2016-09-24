//
//  RouteMatcher.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 A tuple holding components and query parameters, check `matchRoute` for more details
 */
public typealias URLInfo = (components: [String : String], queryParameters: [URLQueryItem])

/**
 Match a route and a requestURL. A route is composed by a baseURL and a path, together they should match the given requestURL.
 To match a route the baseURL must be contained in the requestURL, the substring of the requestURL following the baseURL then is tested against the path to check if they match.
 A baseURL can contain a scheme, and the requestURL must match the scheme; if it doesn't contain a scheme then the baseURL is a wildcard and will be matched by any subdomain or any scheme:
 
 - base: `http://kakapo.com`, path: "any", requestURL: "http://kakapo.com/any" ✅
 - base: `http://kakapo.com`, path: "any", requestURL: "https://kakapo.com/any" ❌ because it's **https**
 - base: `kakapo.com`, path: "any", requestURL: "https://kakapo.com/any" ✅
 - base: `kakapo.com`, path: "any", requestURL: "https://api.kakapo.com/any" ✅
 
 A path can contain wildcard components prefixed with ":" (e.g. /users/:userid) that are used to build the component dictionary, the wildcard is then used as key and the respective component of the requestURL is used as value.
 Any component that is not a wildcard have to be exactly the same in both the path and the request, otherwise the route won't match.
 
 - `/users/:userid` and `/users/1234` ✅ -> `[userid: 1234]`
 - `/comment/:commentid` and `/users/1234` ❌

 QueryParameters are stripped from requestURL before the matching and used to fill `URLInfo.queryParamters`, anything after "?" won't affect the matching.
 
 - parameter baseURL:    The base url, can contain the scheme or not but must be contained in the `requestURL`, (e.g. http://kakapo.com/api) if the baseURL doesn't contain the scheme it's considered as a wildcard that match any scheme and subdomain, see the examples above.
 - parameter path:       The path of the request, can contain wildcards components prefixed with ":" (e.g. /users/:id/)
 - parameter requestURL: The URL of the request (e.g. https://kakapo.com/api/users/1234)
 
 - returns: A URL info object containing `components` and `queryParameters` or nil if `requestURL`doesn't match the route.
 */
func matchRoute(_ baseURL: String, path: String, requestURL: URL) -> URLInfo? {
    
    // remove the baseURL and the params, if baseURL is not in the string the result will be nil
    guard let relevantURL: String = {
        let string = requestURL.absoluteString // http://kakapo.com/api/users/1234?a=b
        let stringWithoutParams = string.substring(.to, string: "?") ?? string // http://kakapo.com/api/users/1234
        return stringWithoutParams.substring(.from, string: baseURL) // `/api/users`
        }() else { return nil }
    
    let routePathComponents = path.split("/") // e.g. [users, :userid]
    let requestPathComponents = relevantURL.split("/") // e.g. [users, 1234]

    guard routePathComponents.count == requestPathComponents.count else {
        // different components count means that the path can't match
        return nil
    }
    
    var components: [String : String] = [:]

    for (routeComponent, requestComponent) in zip(routePathComponents, requestPathComponents) {
        // [users, users], [:userid, 1234]
        
        // if they are not equal then it must be a key prefixed by ":" otherwise the route is not matched
        if routeComponent == requestComponent {
            continue // not a wildcard, no need to insert it in components
        } else {
            guard let firstChar = routeComponent.characters.first, firstChar == ":" else {
                return nil // not equal nor a wildcard
            }
        }
        
        let relevantKeyIndex = routeComponent.characters.index(after: routeComponent.characters.startIndex) // second position
        let key = routeComponent.substring(from: relevantKeyIndex) // :key -> key
        components[key] = requestComponent
    }

    // get the parameters [a:b]
    let queryItems = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)?.queryItems

    return (components, queryItems ?? [])
}

private extension String {
    
    func split(_ separator: Character) -> [String] {
        return characters.split(separator: separator).map { String($0) }
    }
    
    enum SplitMode {
        case from
        case to
    }
    
    /**
     Return the substring From/To a given string or nil if the string is not contained.
     - **from**: return the substring following the given string (e.g. `kakapo.com/users`, `kakapo.com` -> `/users`)
     - **to**: return the substring preceding the given string (e.g. `kakapo.com/users?a=b`, `?` -> `kakapo.com/users`)
     */
    func substring(_ mode: SplitMode, string: String) -> String? {
        guard !string.characters.isEmpty else {
            return self
        }
        
        guard let range = range(of: string) else {
            return nil
        }
        
        switch mode {
        case .from:
            return substring(from: range.upperBound)
        case .to:
            return substring(to: range.lowerBound)
        }
    }
}
