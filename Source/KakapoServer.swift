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
    public let queryParameters: [NSURLQueryItem]
    public let HTTPBody: NSData?
    public let HTTPHeaders: [String: String]?
}

public struct Response: CustomSerializable {
    let code: Int
    let body: Serializable
    let headerFields: [String : String]?
    
    public init(code: Int, body: Serializable, headerFields: [String : String]? = nil) {
        self.code = code
        self.body = body
        self.headerFields = headerFields
    }
    
    public func customSerialize() -> AnyObject {
        return body.serialize()
    }
}

public class Router {
    
    private enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    private typealias Route = (method: HTTPMethod, handler: RouteHandler)
    
    private var routes: [String : Route] = [:]
    public let host: String
    
    init(host: String) {
        self.host = host
    }
    
    func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard let requestURL = request.URL,
                  components = NSURLComponents(URL: requestURL, resolvingAgainstBaseURL: requestURL.baseURL != nil) else { return false }
        
        for (key, route) in routes {
            if  route.method.rawValue == request.HTTPMethod &&
                decomposeURL(key, requestURLComponents: components) != nil {
                return true
            }
        }
        
        return false
    }
    
    func startLoading(server: NSURLProtocol) {
        guard let requestURL = server.request.URL,
                  components = NSURLComponents(URL: requestURL, resolvingAgainstBaseURL: requestURL.baseURL != nil),
                  client = server.client else { return }
        
        var statusCode = 200
        var headerFields = [String : String]?()
        var dataBody: NSData?
        var serializableObject: Serializable?
        
        for (key, route) in routes {
            if let info = decomposeURL(key, requestURLComponents: components) {
                
                if let dataFromNSURLRequest = server.request.HTTPBody {
                    dataBody = dataFromNSURLRequest
                } else if let dataFromProtocol = NSURLProtocol.propertyForKey(RequestHTTPBodyKey, inRequest: server.request) as? NSData {
                    // Using NSURLProtocol property after swizzling NSURLRequest here
                    dataBody = dataFromProtocol
                }
                
                serializableObject = route.handler(Request(components: info.components, queryParameters: info.queryParameters, HTTPBody: dataBody, HTTPHeaders: server.request.allHTTPHeaderFields))
                break
            }
        }
        
        if let serializableObject = serializableObject as? Response {
            statusCode = serializableObject.code
            headerFields = serializableObject.headerFields
        }
        
        if let response = NSHTTPURLResponse(URL: requestURL, statusCode: statusCode, HTTPVersion: "HTTP/1.1", headerFields: headerFields) {
            client.URLProtocol(server, didReceiveResponse: response, cacheStoragePolicy: .AllowedInMemoryOnly)
        }
        
        if let data = serializableObject?.toData() {
            client.URLProtocol(server, didLoadData: data)
        }
        
        client.URLProtocolDidFinishLoading(server)
    }
    
    public func get(urlString: String, handler: RouteHandler) {
        routes[urlString] = (.GET, handler)
    }
    
    public func post(urlString: String, handler: RouteHandler) {
        routes[urlString] = (.POST, handler)
    }
    
    public func del(urlString: String, handler: RouteHandler) {
        routes[urlString] = (.DELETE, handler)
    }
    
    public func put(urlString: String, handler: RouteHandler) {
        routes[urlString] = (.PUT, handler)
    }
    
}

public class KakapoServer: NSURLProtocol {
    
    private static var routers: [String : Router] = [:]
    
    public class func register(host: String) -> Router {
        NSURLProtocol.registerClass(self)
        
        let router = Router(host: host)
        routers[host] = router

        return router
    }
    
    public class func unregister(host: String) {
        routers.removeValueForKey(host)
    }
    
    public class func disable() {
        routers = [:]
        NSURLProtocol.unregisterClass(self)
    }
    
    override public class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard let host = request.URL?.host,
                  router = KakapoServer.routers[host] else { return false }
        
        return router.canInitWithRequest(request)
    }
    
    override public class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override public func startLoading() {
        guard let host = request.URL?.host,
                  router = KakapoServer.routers[host] else { return }
        
        router.startLoading(self)
    }
    
    override public func stopLoading() {}
    
}
