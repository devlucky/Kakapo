//
//  KakapoServer.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 A RouteHandler used when registering different HTTP methods. This can return any Serializable object, though you would normally want to use the built-in Response object
 */
public typealias RouteHandler = Request -> Serializable?

/**
 A Request struct used in `RouteHandlers` to provide valid requests.
 */
public struct Request {
    /// The decomposed URLInfo components
    public let components: [String : String]
    
    /// The decomposed URLInfo query parameters
    public let queryParameters: [NSURLQueryItem]
    
    /// An optional request body
    public let HTTPBody: NSData?
    
    /// An optional dictionary holding the request header fields
    public let HTTPHeaders: [String: String]?
}

/**
 A Response struct which can be used in `RouteHandlers` to provide valid responses.
 */
public struct Response: CustomSerializable {
    /// The response code
    let code: Int
    
    /// The Serializable body object
    let body: Serializable
    
    /// An optional dictionary holding the response header fields
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

/**
 A Router object is an object in charge of intercepting outgoing network calls in order to return custom objects. You register new Router objects by using the KakapoServer class.
 
 After that, the router can be used to register different HTTP methods (GET, POST, DEL, PUT) with custom `RouteHandlers`
 */
public class Router {
    
    private typealias Route = (method: HTTPMethod, handler: RouteHandler)
    
    private enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    private var routes: [String : Route] = [:]
    
    /// The `baseURL` of the Router
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
    
    /**
     Registers a GET request in a given relative path
     
     - parameter relativePath: A relative URL path to be registered
     - parameter handler: A `RouteHandler` handler that will be used when intercepting the `path` with the `baseURL` for a GET request
     */
    public func get(relativePath: String, handler: RouteHandler) {
        routes[relativePath] = (.GET, handler)
    }
    
    /**
     Registers a POST request in a given relative path
     
     - parameter relativePath: A relative URL path to be registered
     - parameter handler: A `RouteHandler` handler that will be used when intercepting the `path` with the `baseURL` for a POST request
     */
    public func post(relativePath: String, handler: RouteHandler) {
        routes[relativePath] = (.POST, handler)
    }
    
    /**
     Registers a DEL request in a given relative path
     
     - parameter relativePath: A relative URL path to be registered
     - parameter handler: A `RouteHandler` handler that will be used when intercepting the `path` with the `baseURL` for a DEL request
     */
    public func del(relativePath: String, handler: RouteHandler) {
        routes[relativePath] = (.DELETE, handler)
    }
    
    /**
     Registers a PUT request in a given relative path
     
     - parameter relativePath: A relative URL path to be registered
     - parameter handler: A `RouteHandler` handler that will be used when intercepting the `path` with the `baseURL` for a PUT request
     */
    public func put(relativePath: String, handler: RouteHandler) {
        routes[relativePath] = (.PUT, handler)
    }
    
}

/**
 A server that conforms to NSURLProtocol in order to intercept outgoing network communication
 */
public class KakapoServer: NSURLProtocol {
    
    private static var routers: [Router] = []
    
    /**
     Register and return a new Router in the Server
     
     - parameter baseURL: The base URL that this Router will use
     
     - returns: An new initialized Router. Note that two Router objects can hold the same baseURL.
     */
    public class func register(baseURL: String) -> Router {
        NSURLProtocol.registerClass(self)
        
        let router = Router(baseURL: baseURL)
        routers.append(router)

        return router
    }
    
    /**
     Unregister any Routers with a given baseURL
     
     - parameter baseURL: The base URL to be unregistered
     */
    public class func unregister(baseURL: String) {
        routers = routers.filter { $0.baseURL != baseURL }
    }
    
    /**
     Disables the Server so that it stops intercepting outgoing requests
     */
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
