//
//  KakapoServer.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

public typealias RouteHandler = Request -> Serializable?

public struct Request {
    public let components: [String : String]
    public let queryParameters: [String : String]
    public let HTTPBody: NSData?
}

public struct Response: CustomSerializable {
    let code: Int
    let body: Serializable
    let headerFields: [String : String]?
    
    init(code: Int, body: Serializable, headerFields: [String : String]? = nil) {
        self.code = code
        self.body = body
        self.headerFields = headerFields
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
        guard let URL = request.URL,
                  client = client else { return }
        
        var statusCode = 200
        var headerFields = [String : String]?()
        var dataBody: NSData?
        var serializableObject: Serializable?
        
        for (key, route) in KakapoServer.routes {
            if let info = parseUrl(key, requestURL: URL.absoluteString) {
                
                if let dataFromNSURLRequest = request.HTTPBody {
                    dataBody = dataFromNSURLRequest
                } else if let dataFromProtocol = NSURLProtocol.propertyForKey(RequestHTTPBodyKey, inRequest: request) as? NSData {
                    // Using NSURLProtocol property after swizzling NSURLRequest here
                    dataBody = dataFromProtocol
                }
                
                serializableObject = route.handler(Request(components: info.components, queryParameters: info.queryParameters, HTTPBody: dataBody))
                break
            }
        }
        
        if let serializableObject = serializableObject as? Response {
            statusCode = serializableObject.code
            headerFields = serializableObject.headerFields
        }
        
        if let response = NSHTTPURLResponse(URL: URL, statusCode: statusCode, HTTPVersion: "HTTP/1.1", headerFields: headerFields) {
            client.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .AllowedInMemoryOnly)
        }
        
        if let data = serializableObject?.toData() {
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
    
}
