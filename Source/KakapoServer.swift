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
    
    private typealias Route = (method: HTTPMethod, handler: RouteHandler)
    
    private enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    private var routes: [String : Route] = [:]
    public let baseURL: String
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard let requestURL = request.URL,
                  components = requestURL.componentsFromBaseURL(baseURL) else { return false }
        
        for (key, route) in routes where route.method.rawValue == request.HTTPMethod {
            if  decomposeURL(key, requestURLComponents: components) != nil {
                return true
            }
        }
        
        return false
    }
    
    func startLoading(server: NSURLProtocol) {
        guard let requestURL = server.request.URL,
                  components = requestURL.componentsFromBaseURL(baseURL),
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
    
    private static var routers: [Router] = []
    
    public class func register(baseURL: String) -> Router {
        NSURLProtocol.registerClass(self)
        
        let router = Router(baseURL: baseURL)
        routers.append(router)

        return router
    }
    
    public class func unregister(baseURL: String) {
        routers = routers.filter { $0.baseURL != baseURL }
    }
    
    public class func disable() {
        routers = []
        NSURLProtocol.unregisterClass(self)
    }
    
    override public class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard let URL = request.URL else { return false }
        
        return
            routers.filter { URL.absoluteString.containsString($0.baseURL) && $0.canInitWithRequest(request) }.first != nil ? true : false
    }
    
    override public class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override public func startLoading() {
        guard let URL = request.URL else { return }
        
        KakapoServer.routers.filter { URL.absoluteString.containsString($0.baseURL) && $0.canInitWithRequest(request) }.first?.startLoading(self)
    }
    
    override public func stopLoading() {}
    
}

private extension NSURL {
    
    func componentsFromBaseURL(baseURL: String) -> NSURLComponents? {
        return NSURLComponents(string: absoluteString.stringByReplacingOccurrencesOfString(baseURL, withString: ""))
    }
    
}
