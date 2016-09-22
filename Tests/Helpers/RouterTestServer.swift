//
//  RouterTestServer.swift
//  Kakapo
//
//  Created by Alex Manzella on 22/09/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 A test server that conforms to NSURLProtocol, in order to intercept outgoing network for unit tests.
 As `NSURLProtocol` documentation states:
 
 "Classes are consulted in the reverse order of their registration.
 A similar design governs the process to create the canonical form of a request with canonicalRequestForRequest:."
 
 Thus, we use this test server to intercept real network calls in tests as a fallback for `Server`.
 */
final class RouterTestServer: NSURLProtocol {
    
    class func register() {
        NSURLProtocol.registerClass(self)
    }
    
    class func disable() {
        NSURLProtocol.unregisterClass(self)
    }
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override func startLoading() {
        guard let requestURL = request.URL,
            client = client else { return }
        
        let response = NSHTTPURLResponse(URL: requestURL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: nil)!
        client.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .AllowedInMemoryOnly)
        client.URLProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
