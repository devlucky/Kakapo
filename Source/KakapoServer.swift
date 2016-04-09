//
//  KakapoServer.swift
//  KakapoExample
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

extension NSURLRequest {
    
    private struct AssociatedKeys {
        static var RequestHTTPBody = "kkp_requestHTTPBody"
    }
    
    var requestHTTPBody: NSData? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.RequestHTTPBody) as? NSData
        }
        
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.RequestHTTPBody, newValue as NSData?, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
}

extension NSURLRequest {
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            let originalSelector0 = Selector("copy") //#selector(copy as () -> AnyObject)
            let swizzledSelector0 = Selector("kkp_copy") //#selector(kkp_copy)
            let originalSelector = Selector("copyWithZone:") //#selector(copy as () -> AnyObject)
            let swizzledSelector = Selector("kkp_copyWithZone:") //#selector(kkp_copy)
            
            let originalMethod0 = class_getInstanceMethod(self, originalSelector0)
            let swizzledMethod0 = class_getInstanceMethod(self, swizzledSelector0)
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let didAddMethod0 = class_addMethod(self, originalSelector0, method_getImplementation(swizzledMethod0), method_getTypeEncoding(swizzledMethod0))
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethod0 {
                class_replaceMethod(self, swizzledSelector0, method_getImplementation(originalMethod0), method_getTypeEncoding(originalMethod0))
            } else {
                method_exchangeImplementations(originalMethod0, swizzledMethod0)
            }
            
            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
    
    func kkp_copyWithZone(zone: NSZone) -> AnyObject {
        let theCopy: NSMutableURLRequest = self.kkp_copyWithZone(zone).mutableCopy() as! NSMutableURLRequest
        theCopy.requestHTTPBody = HTTPBody
//        theCopy.setValue(theCopy.HTTPBody, forKey: "requestHTTPBody")
        //        theCopy.requestHTTPBody = theCopy.HTTPBody
        return theCopy
    }

    
    // MARK: - Method Swizzling
    func kkp_copy() -> AnyObject {
        let theCopy = self.kkp_copy()
//        theCopy.setValue(theCopy.HTTPBody, forKey: "requestHTTPBody")
//        theCopy.requestHTTPBody = theCopy.HTTPBody
        return theCopy
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
        let HTTPBody: [String : String]?
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
                var body: [String: String]?
                if let httpBody = request.HTTPBody,
                       serializedBody = try? NSJSONSerialization.JSONObjectWithData(httpBody, options: .MutableLeaves) as? [String: String] {
                    body = serializedBody
                }
                
                object.handler(request: Request(info: info, HTTPBody: body))
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

