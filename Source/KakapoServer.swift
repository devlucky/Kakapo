//
//  KakapoServer.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

class KakapoServer: NSURLProtocol {
    
    typealias Route = (method: HTTPMethod, handler: (request: Request) -> ())
    
    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    struct Request {
        let urlString: String
        let info: URLInfo
    }
    
    private static var routes: [String : Route] = [:]
    
    class func enable() {
        NSURLProtocol.registerClass(self)
    }
    
    class func disable() {
        routes = [:]
        NSURLProtocol.unregisterClass(self)
    }
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard let requestString = request.URL?.absoluteString else { return false }
        
        for (key, object) in routes {
            if object.method.rawValue == request.HTTPMethod && parseUrl(key, requestURL: requestString) != nil {
                return true
            }
        }
        
        return false
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(a: NSURLRequest, toRequest b: NSURLRequest) -> Bool {
        return false
    }
    
    override func startLoading() {
        guard let requestString = request.URL?.absoluteString else { return }
        
        for (key, object) in KakapoServer.routes {
            if let info = parseUrl(key, requestURL: requestString) {
                object.handler(request: Request(urlString: requestString, info: info))
            }
        }
        
        // TODO: serialize and send data back here
        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "", headerFields: nil)
        client?.URLProtocol(self, didReceiveResponse: response!, cacheStoragePolicy: .AllowedInMemoryOnly)
        client?.URLProtocol(self, didLoadData: "some data".dataUsingEncoding(NSUTF8StringEncoding)!)
        client?.URLProtocolDidFinishLoading(self)
    }
    
    
    override func stopLoading() {
        
    }
    
    static func get(urlString: String, handler: (request: Request) -> ()) {
        KakapoServer.routes[urlString] = (.GET, handler)
    }
    
    static func post(urlString: String, handler: (request: Request) -> ()) {
        KakapoServer.routes[urlString] = (.POST, handler)
    }
    
    static func del(urlString: String, handler: (request: Request) -> ()) {
        KakapoServer.routes[urlString] = (.DELETE, handler)
    }
    
    static func put(urlString: String, handler: (request: Request) -> ()) {
        KakapoServer.routes[urlString] = (.PUT, handler)
    }
    
}

