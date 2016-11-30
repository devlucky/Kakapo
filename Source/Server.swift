//
//  Server.swift
//  Kakapo
//
//  Created by Joan Romano on 30/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 A server that conforms to `NSURLProtocol` in order to intercept outgoing network communication.
 You shouldn't use this class directly but register a `Router` instead.
 Since frameworks like **AFNetworking** and **Alamofire** require manual registration of the `NSURLProtocol` classes
 you will need to register this class when needed.

 ### Examples
 
 1- Configure `NSURLSessionConfiguration` by adding `Server` to `protocolClasses`:
 
 ```
 let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
 configuration.protocolClasses = [Server.self]
 // NOTE: better to just add if is not nil
```
 
 2- Setup the URL Session Manager
 
 #### AFNetworking
 
 ```
 let manager = AFURLSessionManager(sessionConfiguration: configuration)
 ```
 
 #### Alamofire
 
 ```
 let manager = Manager(configuration: configuration)
 ```
 */
public final class Server: NSURLProtocol {

    private static var routers: [Router] = []

    /**
     `true`, if the `request` of the `Server` instance has been cancelled, otherwise `false`.

     Default: `false`

     Note: calls to `stopLoading()` will set this value to `true`
     */
    private(set) var requestCancelled: Bool = false
    
    /**
     Register and return a new Router in the Server
     
     - parameter baseURL: The base URL that this Router will use
     
     - returns: A newly initialized Router object, which is configured to use the `baseURL`.
     */
    class func register(baseURL: String) -> Router {
        NSURLProtocol.registerClass(self)
        
        let router = Router(baseURL: baseURL)
        routers.append(router)
        
        return router
    }
    
    /**
     Unregister any Routers with a given baseURL
     
     - parameter baseURL: The base URL to be unregistered
     */
    class func unregister(baseURL: String) {
        routers = routers.filter { $0.baseURL != baseURL }
    }
    
    /**
     Disables the Server so that it stops intercepting outgoing requests
     */
    class func disable() {
        routers = []
        NSURLProtocol.unregisterClass(self)
    }
    
    /**
     `Server` checks if the given request matches any of the registered routes
     and determines if the request should be intercepted.

     Note: If this method returns `true`, then the OS will create a new `Server` instance for the `request`
           via the `init(request:cachedResponse:client:)` initializer. So, this `request` is the same, which
           we'll have access to later on in the `startLoading()` and `stopLoading()` methods.
     
     - parameter request: A request
     
     - returns: true if any of the registered route match the request URL
     */
    override public class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return routers.indexOf({ $0.canInitWithRequest(request) }) != nil
    }
    
    /// Just returns the given request without changes
    override public class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    /// Start loading the matched requested, the route handler will be called and the returned object will be serialized.
    override public func startLoading() {
        if let routerIndex = Server.routers.indexOf({ $0.canInitWithRequest(request) }) {
            let router = Server.routers[routerIndex]
            let latency = router.latency
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(latency * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                if !self.requestCancelled {
                    router.startLoading(self)
                }
            }
        }
    }
    
    /// Stops the loading of the matched request.
    override public func stopLoading() {
        requestCancelled = true
    }
}
