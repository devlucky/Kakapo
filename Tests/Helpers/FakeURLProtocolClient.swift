//
//  FakeURLProtocolClient.swift
//  Kakapo
//
//  Created by Alex Manzella on 22/09/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

final class FakeURLProtocolClient: NSObject, URLProtocolClient {
    @objc func urlProtocol(_ protocol: URLProtocol, wasRedirectedTo request: URLRequest, redirectResponse: URLResponse) { /* intentionally left empty */ }
    @objc func urlProtocol(_ protocol: URLProtocol, cachedResponseIsValid cachedResponse: CachedURLResponse) { /* intentionally left empty */ }
    @objc func urlProtocol(_ protocol: URLProtocol, didReceive response: URLResponse, cacheStoragePolicy policy: URLCache.StoragePolicy) { /* intentionally left empty */ }
    @objc func urlProtocol(_ protocol: URLProtocol, didLoad data: Data) { /* intentionally left empty */ }
    @objc func urlProtocolDidFinishLoading(_ protocol: URLProtocol) { /* intentionally left empty */ }
    @objc func urlProtocol(_ protocol: URLProtocol, didFailWithError error: Error) { /* intentionally left empty */ }
    @objc func urlProtocol(_ protocol: URLProtocol, didReceive challenge: URLAuthenticationChallenge) { /* intentionally left empty */ }
    @objc func urlProtocol(_ protocol: URLProtocol, didCancel challenge: URLAuthenticationChallenge) { /* intentionally left empty */ }
}
