//
//  KakapoServer.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

private let RequestHTTPBodyKey = "kkp_requestHTTPBody"

/**
 We swizzle NSURLRequest to be able to use the HTTPBody when handling NSURLSession. If a custom NSURLProtocol is provided to NSURLSession, 
 even if the NSURLRequest has an HTTPBody non-nil when the request is passed to the NRURLProtocol (such as canInitWithRequest: or 
 canonicalRequestForRequest:) has an empty body.
 
 **[See radar](http://openradar.appspot.com/15993891)**
 **[See issue #9](https://github.com/devlucky/Kakapo/issues/9)**
 **[See relevant issue](https://github.com/AliSoftware/OHHTTPStubs/issues/52)**
 */
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
            NSURLProtocol.setProperty(body, forKey: RequestHTTPBodyKey, inRequest: request)
        }
        
        return self.kkp_copy()
    }
}

class KakapoServer: NSURLProtocol {
    
    typealias Route = (method: HTTPMethod, handler: (request: Request) -> ())
    
    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    struct Request {
        let info: URLInfo
        let HTTPBody: NSData?
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
    
    override func startLoading() {
        guard let requestString = request.URL?.absoluteString else { return }
        var dataBody: NSData?
        
        for (key, object) in KakapoServer.routes {
            if let info = parseUrl(key, requestURL: requestString) {
                
                if let dataFromNSURLRequest = request.HTTPBody {
                    dataBody = dataFromNSURLRequest
                } else if let dataFromProtocol = NSURLProtocol.propertyForKey(RequestHTTPBodyKey, inRequest: request) as? NSData {
                    // Using NSURLProtocol property after swizzling NSURLRequest here
                    dataBody = dataFromProtocol
                }
                
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

