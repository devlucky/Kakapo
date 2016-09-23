//
//  FakeURLProtocolClient.swift
//  Kakapo
//
//  Created by Alex Manzella on 22/09/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

final class FakeURLProtocolClient: NSObject, NSURLProtocolClient {
    @objc func URLProtocol(`protocol`: NSURLProtocol, wasRedirectedToRequest request: NSURLRequest, redirectResponse: NSURLResponse) { /* intentionally left empty */ }
    @objc func URLProtocol(`protocol`: NSURLProtocol, cachedResponseIsValid cachedResponse: NSCachedURLResponse) { /* intentionally left empty */ }
    @objc func URLProtocol(`protocol`: NSURLProtocol, didReceiveResponse response: NSURLResponse, cacheStoragePolicy policy: NSURLCacheStoragePolicy) { /* intentionally left empty */ }
    @objc func URLProtocol(`protocol`: NSURLProtocol, didLoadData data: NSData) { /* intentionally left empty */ }
    @objc func URLProtocolDidFinishLoading(`protocol`: NSURLProtocol) { /* intentionally left empty */ }
    @objc func URLProtocol(`protocol`: NSURLProtocol, didFailWithError error: NSError) { /* intentionally left empty */ }
    @objc func URLProtocol(`protocol`: NSURLProtocol, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge) { /* intentionally left empty */ }
    @objc func URLProtocol(`protocol`: NSURLProtocol, didCancelAuthenticationChallenge challenge: NSURLAuthenticationChallenge) { /* intentionally left empty */ }
}
