//
//  KakapoServer.swift
//  KakapoExample
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

class KakapoServer: NSURLProtocol {
    
    typealias KakapoLookupObject = (method: KakapoServerMethod,
                                    handler: (request: KakapoRequest) -> ())
    
    enum KakapoServerMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    struct KakapoRequest {
        let urlString: String
        let params: [String : AnyObject]
    }
    
    private static var routes: [String : KakapoLookupObject] = [:]
    
    class func enable() {
        NSURLProtocol.registerClass(self)
    }
    
    class func disable() {
        NSURLProtocol.unregisterClass(self)
    }
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard let requestString = request.URL?.absoluteString else { return false }
        
        for (key, object) in routes {
            if object.method.rawValue == request.HTTPMethod && checkUrl(key, requestUrl: requestString) != nil {
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
            if let params = checkUrl(key, requestUrl: requestString) {
                object.handler(request: KakapoRequest(urlString: requestString, params: params))
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
    
    func get(urlString: String, handler: (request: KakapoRequest) -> ()) {
        KakapoServer.routes[urlString] = (.GET, handler)
    }
    
    func post(urlString: String, handler: (request: KakapoRequest) -> ()) {
        KakapoServer.routes[urlString] = (.POST, handler)
    }
    
    func del(urlString: String, handler: (request: KakapoRequest) -> ()) {
        KakapoServer.routes[urlString] = (.DELETE, handler)
    }
    
    func put(urlString: String, handler: (request: KakapoRequest) -> ()) {
        KakapoServer.routes[urlString] = (.PUT, handler)
    }
    
}

