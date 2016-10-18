//
//  RouterTestServer.swift
//  Kakapo
//
//  Created by Alex Manzella on 22/09/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 A test server that conforms to URLProtocol, in order to intercept outgoing network for unit tests.
 As `URLProtocol` documentation states:
 
 "Classes are consulted in the reverse order of their registration.
 A similar design governs the process to create the canonical form of a request with canonicalRequestForRequest:."
 
 Thus, we use this test server to intercept real network calls in tests as a fallback for `Server`.
 */
final class RouterTestServer: URLProtocol {
    
    class func register() {
        URLProtocol.registerClass(self)
    }
    
    class func disable() {
        URLProtocol.unregisterClass(self)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let requestURL = request.url,
            let client = client else { return }
        
        let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowedInMemoryOnly)
        client.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
