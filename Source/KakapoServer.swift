//
//  KakapoServer.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

public class KakapoServer: NSURLProtocol {
    
    public typealias RouteHandler = Request -> Serializable?
    
    public struct Request {
        let info: URLInfo
        let HTTPBody: NSData?
    }

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
        
        var dataBody: NSData?
        var serializableObjects: Serializable?
        
        for (key, route) in KakapoServer.routes {
            if let info = parseUrl(key, requestURL: requestString) {
                
                if let dataFromNSURLRequest = request.HTTPBody {
                    dataBody = dataFromNSURLRequest
                } else if let dataFromProtocol = NSURLProtocol.propertyForKey(RequestHTTPBodyKey, inRequest: request) as? NSData {
                    // Using NSURLProtocol property after swizzling NSURLRequest, see NSURLRequest+FixCopy.swift
                    dataBody = dataFromProtocol
                }
                
                serializableObjects = route.handler(Request(info: info, HTTPBody: dataBody))
                break
            }
        }
        
        // TODO: handle status codes and header fields
        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "", headerFields: nil)
        client.URLProtocol(self, didReceiveResponse: response!, cacheStoragePolicy: .AllowedInMemoryOnly)
        
        if let serialized = serializableObjects?.serialize(), let data = toData(serialized) {
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
