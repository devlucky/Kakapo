//
//  KakapoServer.swift
//  KakapoExample
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

private let kkp_RequestHTTPBodyKey = "kkp_requestHTTPBody"

extension NSURLRequest {
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            let originalSelector = Selector("copy") //#selector(copy as () -> AnyObject)
            let swizzledSelector = Selector("kkp_copy") //#selector(kkp_copy)
            
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }

    
    // MARK: - Method Swizzling
    func kkp_copy() -> AnyObject {
        if let request = self as? NSMutableURLRequest,
               body = HTTPBody {
            NSURLProtocol.setProperty(body, forKey: kkp_RequestHTTPBodyKey, inRequest: request)
        }
        
        return self.kkp_copy()
    }
}

class KakapoServer: NSURLProtocol {
    
    typealias LookupObject = (method: HTTPMethod,
                              handler: (request: Request) -> ())
    
    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    struct Request {
        let info: URLInfo
        let HTTPBody: NSData?
    }
    
    private static var routes: [String : LookupObject] = [:]
    
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
                
                let dataBody = NSURLProtocol.propertyForKey(kkp_RequestHTTPBodyKey, inRequest: request) as? NSData
                
                object.handler(request: Request(info: info, HTTPBody: dataBody))
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

