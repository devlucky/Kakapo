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

public typealias RouteHandler = Request -> Serializable?

public struct Request {
    let info: URLInfo
    let HTTPBody: NSData?
}

public struct Response: CustomSerializable {
    let code: Int
    let header: [String : String]?
    let body: Serializable
    
    init(code: Int, header: [String : String]? = nil, body: Serializable) {
        self.code = code
        self.header = header
        self.body = body
    }
    
    public func customSerialize() -> AnyObject {
        return body.serialize()
    }
}

public class KakapoServer: NSURLProtocol {

    private typealias Route = (method: HTTPMethod, handler: RouteHandler)
    
    private enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    private static var routes: [String : Route] = [:]
    
    public class func enable() {
        NSURLProtocol.registerClass(self)
    }
    
    public class func disable() {
        routes = [:]
        NSURLProtocol.unregisterClass(self)
    }
    
    override public class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard let requestString = request.URL?.absoluteString else { return false }
        
        for (key, object) in routes {
            if object.method.rawValue == request.HTTPMethod && parseUrl(key, requestURL: requestString) != nil {
                return true
            }
        }
        
        return false
    }
    
    override public class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override public func startLoading() {
        guard let requestString = request.URL?.absoluteString,
                  client = client else { return }
        
        var statusCode = 200
        var headerFields = [String : String]?()
        var dataBody: NSData?
        var serializableObject: Serializable?
        
        for (key, route) in KakapoServer.routes {
            if let info = parseUrl(key, requestURL: requestString) {
                
                if let dataFromNSURLRequest = request.HTTPBody {
                    dataBody = dataFromNSURLRequest
                } else if let dataFromProtocol = NSURLProtocol.propertyForKey(RequestHTTPBodyKey, inRequest: request) as? NSData {
                    // Using NSURLProtocol property after swizzling NSURLRequest here
                    dataBody = dataFromProtocol
                }
                
                serializableObject = route.handler(Request(info: info, HTTPBody: dataBody))
                break
            }
        }
        
        if let serializableObject = serializableObject as? Response {
            statusCode = serializableObject.code
            headerFields = serializableObject.header
        }
        
        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: statusCode, HTTPVersion: "HTTP/1.1", headerFields: headerFields)
        client.URLProtocol(self, didReceiveResponse: response!, cacheStoragePolicy: .AllowedInMemoryOnly)
        
        if let serialized = serializableObject?.serialize(), let data = toData(serialized) {
            client.URLProtocol(self, didLoadData: data)
        }
        
        client.URLProtocolDidFinishLoading(self)
    }
    
    override public func stopLoading() {}
    
    public static func get(urlString: String, handler: RouteHandler) {
        KakapoServer.routes[urlString] = (.GET, handler)
    }
    
    public static func post(urlString: String, handler: RouteHandler) {
        KakapoServer.routes[urlString] = (.POST, handler)
    }
    
    public static func del(urlString: String, handler: RouteHandler) {
        KakapoServer.routes[urlString] = (.DELETE, handler)
    }
    
    public static func put(urlString: String, handler: RouteHandler) {
        KakapoServer.routes[urlString] = (.PUT, handler)
    }
    
    private func toData(object: AnyObject) -> NSData? {
        if !NSJSONSerialization.isValidJSONObject(object) {
            return nil
        }
        return try? NSJSONSerialization.dataWithJSONObject(object, options: .PrettyPrinted)
    }
    
}
