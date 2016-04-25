//
//  NSURLRequest+FixCopy.swift
//  Kakapo
//
//  Created by Alex Manzella on 17/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

let RequestHTTPBodyKey = "kkp_requestHTTPBody"

/**
 We swizzle NSURLRequest to be able to use the HTTPBody when handling NSURLSession. If a custom NSURLProtocol is provided to NSURLSession, 
 even if the NSURLRequest has an HTTPBody non-nil when the request is passed to the NRURLProtocol (such as canInitWithRequest: or 
 canonicalRequestForRequest:) has an empty body.
 
 **[See radar](http://openradar.appspot.com/15993891)**
 **[See issue #9](https://github.com/devlucky/Kakapo/issues/9)**
 **[See relevant issue](https://github.com/AliSoftware/OHHTTPStubs/issues/52)**
 */
extension NSMutableURLRequest {
    
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            let originalSelector = Selector("setHTTPBody:")
            let swizzledSelector = #selector(NSMutableURLRequest.kkp_setHTTPBody(_:))
            
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
    func kkp_setHTTPBody(body: NSData?) {
        if let body = body {
            NSURLProtocol.setProperty(body, forKey: RequestHTTPBodyKey, inRequest: self)
        }
        
        self.kkp_setHTTPBody(body)
    }
}
