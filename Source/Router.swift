//
//  Router.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 A RouteHandler used when registering different HTTP methods, which can return any Serializable object.
 
 By default, though, the Router will return a 200 status code and no header fields when only returning a Serializable object.
 In order to customize that behavior, check `ResponseFieldsProvider` to provide custom status code and header fields.
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
 A protocol to adopt when a `Serializable object needs to also provide response status code and/or headerFields
 For example you may use `Response` to wrap your `Serializable` object to just achieve the result or directly implement the protocol. For examply `JSONAPISerializer` implement the protocol in order to be able to provide custom status code in the response.
 */
public protocol ResponseFieldsProvider: CustomSerializable {
    /// The response status code
    var statusCode: Int { get }
    
    /// The Serializable body object
    var body: Serializable { get }

    /// An optional dictionary holding the response header fields
    var headerFields: [String : String]? { get }
}

extension ResponseFieldsProvider {
    
    /// The default implementation just return the serialized body.
    public func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
        return body.serialize(keyTransformer)
    }
}

/**
 A ResponseFieldsProvider implementation which can be used in `RouteHandlers` to provide valid responses that can return different status code than the default (200) or headerFields.
 
 The struct provides, appart from a Serializable `body` object, a status code and header fields. 
 */
public struct Response: ResponseFieldsProvider {
    /// The response status code
    public let statusCode: Int
    
    /// The Serializable body object
    public let body: Serializable
    
    /// An optional dictionary holding the response header fields
    public let headerFields: [String : String]?
    
    /**
     Initialize `Response` object that wraps another `Serializable` object for the serialization but, implemententing `ResponseFieldsProvider` can affect some parameters of the HTTP response
     
     - parameter statusCode:   the status code that the response should provide to the HTTP repsonse
     - parameter body:         the body that will be serialized
     - parameter headerFields: the headerFields that the response should provide to the HTTP repsonse
     
     - returns: A wrapper `Serializable` object that affect http requests.
     */
    public init(statusCode: Int, body: Serializable, headerFields: [String : String]? = nil) {
        self.statusCode = statusCode
        self.body = body
        self.headerFields = headerFields
    }
}

/**
 A Router object is an object in charge of intercepting outgoing network calls in order to return custom objects. You register new Router objects by using the `register` class methods.
 
 After that, the router can be used to register different HTTP methods (GET, POST, DEL, PUT) with custom `RouteHandlers`
 */
public final class Router {
    
    private typealias Route = (method: HTTPMethod, handler: RouteHandler)
    
    private enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    private var routes: [String : Route] = [:]
    
    /// The `baseURL` of the Router
    public let baseURL: String
    
    /// The desired latency to delay the mocked responses. Default value is 0.
    public var latency: NSTimeInterval = 0
    
    /**
     Register and return a new Router in the Server
     
     - parameter baseURL: The base URL that this Router will use
     
     - returns: An new initialized Router. Note that two Router objects can hold the same baseURL.
     */
    public class func register(baseURL: String) -> Router {
        return KakapoServer.register(baseURL)
    }
    
    /**
     Unregister any Routers with a given baseURL
     
     - parameter baseURL: The base URL to be unregistered
     */
    public class func unregister(baseURL: String) {
        KakapoServer.unregister(baseURL)
    }
    
    /**
     Disables all Routers, stopping the request intercepting
     */
    public class func disableAll() {
        KakapoServer.disable()
    }
    
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
        
        if let serializableObject = serializableObject as? ResponseFieldsProvider {
            statusCode = serializableObject.statusCode
            headerFields = serializableObject.headerFields
        }
        
        if let response = NSHTTPURLResponse(URL: requestURL, statusCode: statusCode, HTTPVersion: "HTTP/1.1", headerFields: headerFields) {
            client.URLProtocol(server, didReceiveResponse: response, cacheStoragePolicy: .AllowedInMemoryOnly)
        }
        
        if let data = serializableObject?.toData() {
            client.URLProtocol(server, didLoadData: data)
        }
        
        let didFinishLoading: (NSURLProtocol) -> () = { (server) in
            client.URLProtocolDidFinishLoading(server)
        }

        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(latency * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            didFinishLoading(server)
        }
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

private extension NSURL {
    
    func componentsFromBaseURL(baseURL: String) -> NSURLComponents? {
        return NSURLComponents(string: absoluteString.stringByReplacingOccurrencesOfString(baseURL, withString: ""))
    }
    
}
