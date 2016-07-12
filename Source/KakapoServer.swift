//
//  KakapoServer.swift
//  Kakapo
//
//  Created by Joan Romano on 30/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 A server that conforms to NSURLProtocol in order to intercept outgoing network communication.
 You shouldn't use this class directly but register a `Router` instead. Since frameworks like **AFNetworking** and **Alamofire** require manual registration of the `NSURLProtocol` classes you will need to register this class when needed.

 ### Examples
 
 1- Configure `NSURLSessionConfiguration` by adding `KakapoServer` to `protocolClasses`:
 
 ```
 let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
 configuration.protocolClasses = [KakapoServer.self]
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
public final class KakapoServer: NSURLProtocol {
    
    private static var routers: [Router] = []
    
    /**
     Register and return a new Router in the Server
     
     - parameter baseURL: The base URL that this Router will use
     
     - returns: An new initialized Router. Note that two Router objects can hold the same baseURL.
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
    
    override public func stopLoading() {
        /* TODO: implement stopLoading for delayed requests https://github.com/devlucky/Kakapo/issues/88 */
    }
}
