//
//  RouterTests.swift
//  Kakapo
//
//  Created by Joan Romano on 02/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

import Quick
import Nimble
import AFNetworking
import Alamofire

@testable import Kakapo

/**
 A test server that conforms to NSURLProtocol, in order to intercept outgoing network for unit tests. As `NSURLProtocol` documentation states:
 
 "Classes are consulted in the reverse order of their registration. A similar design governs the process to create the canonical form of a request with canonicalRequestForRequest:."
 
 Thus, we use this test server to intercept real network calls in tests as a fallback for `KakapoServer`.
 */
private final class RouterTestServer: NSURLProtocol {

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

        client.URLProtocol(self, didReceiveResponse: NSHTTPURLResponse(URL: requestURL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: nil)!, cacheStoragePolicy: .AllowedInMemoryOnly)
        client.URLProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class ProtocolClientTest: NSObject, NSURLProtocolClient {

    private let shouldFail_URLProtocolDidFinishLoading: Bool
    
    var didCall_URLProtocolDidFinishLoading: Bool = false
    
    init(shouldFail_URLProtocolDidFinishLoading: Bool) {
        self.shouldFail_URLProtocolDidFinishLoading = shouldFail_URLProtocolDidFinishLoading
        super.init()
    }

    @objc func URLProtocol(`protocol`: NSURLProtocol, wasRedirectedToRequest request: NSURLRequest, redirectResponse: NSURLResponse) {
        // intentionally left empty
    }
    @objc func URLProtocol(`protocol`: NSURLProtocol, cachedResponseIsValid cachedResponse: NSCachedURLResponse) {
        // intentionally left empty
    }
    @objc func URLProtocol(`protocol`: NSURLProtocol, didReceiveResponse response: NSURLResponse, cacheStoragePolicy policy: NSURLCacheStoragePolicy) {
        // intentionally left empty
    }
    @objc func URLProtocol(`protocol`: NSURLProtocol, didLoadData data: NSData) {
        // intentionally left empty
    }
    @objc func URLProtocolDidFinishLoading(`protocol`: NSURLProtocol) {
        if shouldFail_URLProtocolDidFinishLoading {
            XCTFail("Protocol client should never get 'URLProtocolDidFinishLoading' called.")
        }
        
        didCall_URLProtocolDidFinishLoading = true
    }
    @objc func URLProtocol(`protocol`: NSURLProtocol, didFailWithError error: NSError) {
        // intentionally left empty
    }
    @objc func URLProtocol(`protocol`: NSURLProtocol, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
        // intentionally left empty
    }
    @objc func URLProtocol(`protocol`: NSURLProtocol, didCancelAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
        // intentionally left empty
    }
}

struct CustomResponse: ResponseFieldsProvider {
    let statusCode: Int
    let body: Serializable
    let headerFields: [String : String]?
    
    init(statusCode: Int, body: Serializable, headerFields: [String : String]? = nil) {
        self.statusCode = statusCode
        self.body = body
        self.headerFields = headerFields
    }
}

class RouterTests: QuickSpec {
    
    override func spec() {
        var db = KakapoDB()
        
        beforeEach{
            RouterTestServer.register()
            db = KakapoDB()
        }
        
        afterEach{
            RouterTestServer.disable()
            Router.disableAll()
        }

        describe("Describe Cancelling requests") {
            var router: Router!
            let baseURL = "http://www.funky-cancel-request-top-level-domain.com"
            let latency = NSTimeInterval(2)

            beforeEach {
                router = Router.register(baseURL)
                router.latency = latency // very high latency to allow us to stop the request before execution
            }

            it("should not start a request when request gets cancelled") {
                var responseURL: NSURL? = nil

                router.get("/feed/:id") { request in
                    XCTFail("Request should get stopped before and should not get executed")
                    return nil
                }

                let requestURL = NSURL(string: "\(baseURL)/feed/1")!
                let dataTask = NSURLSession.sharedSession().dataTaskWithURL(requestURL) { (data, response, _) in
                    responseURL = response?.URL
                }

                dataTask.cancel() // immediately stop the request loading

                expect(responseURL).toEventually(beNil())
            }

            it("should send notifications when loading has finished") {

                router.get("/foobar/:id") { request in
                    return nil
                }

                let requestURL = NSURL(string: "\(baseURL)/foobar/1")!

                // We create a "dummy" NSURLProtocol object here, which is using the same URL (that we used to
                // trigger the request). In order to check the request cancelation.
                let urlRequest = NSURLRequest(URL: requestURL)
                let client = ProtocolClientTest(shouldFail_URLProtocolDidFinishLoading: false)
                let protocolHandler = NSURLProtocol(request: urlRequest, cachedResponse: nil, client: client)

                router.startLoading(protocolHandler)

                expect(client.didCall_URLProtocolDidFinishLoading).toEventually(beTruthy(), timeout: (latency + 1))
            }

            it("should NOT send notifications when loading has been cancelled") {

                router.get("/fancy-stuff/:id") { request in
                    return nil
                }

                let requestURL = NSURL(string: "\(baseURL)/fancy-stuff/1")!

                // We create a "dummy" NSURLProtocol object here, which is using the same URL (that we used to
                // trigger the request). In order to check the request cancelation.
                let urlRequest = NSURLRequest(URL: requestURL)
                let client = ProtocolClientTest(shouldFail_URLProtocolDidFinishLoading: true)
                let protocolHandler = NSURLProtocol(request: urlRequest, cachedResponse: nil, client: client)

                expect(router.numberOfCancelledRequests).to(equal(0))
                router.stopLoading(protocolHandler) // tell the router to stop the request (before it has been started)
                expect(router.numberOfCancelledRequests).to(equal(1))
                router.startLoading(protocolHandler)

                expect(router.numberOfCancelledRequests).toEventually(equal(0), timeout: (latency + 1))
            }

            it("should increase number of cancelled requests") {
                let requestURL = NSURL(string: "\(baseURL)/moon/1")!

                // We create a "dummy" NSURLProtocol object here, which is using the same URL (that we used to
                // trigger the request). In order to check the request cancelation.
                let urlRequest = NSURLRequest(URL: requestURL)
                let client = ProtocolClientTest(shouldFail_URLProtocolDidFinishLoading: true)
                let protocolHandler = NSURLProtocol(request: urlRequest, cachedResponse: nil, client: client)

                expect(router.numberOfCancelledRequests).to(equal(0))
                router.stopLoading(protocolHandler)
                expect(router.numberOfCancelledRequests).to(equal(1))
            }

            it("should do nothing when no URL is provided") {
                let requestURL = NSURL(string: "\(baseURL)/alpha/1")!
                let urlRequest = NSMutableURLRequest(URL: requestURL)
                urlRequest.URL = nil
                let protocolHandler = NSURLProtocol(request: urlRequest, cachedResponse: nil, client: nil)
                router.stopLoading(protocolHandler)
            }
        }

        describe("Registering urls") {
            var router: Router!
            
            beforeEach{
                router = Router.register("http://www.test.com")
            }
            
            context("when the Router is initialized") {
                it("should not have latency") {
                    expect(router.latency) == 0
                }
            }
            
            it("should call the handler when requesting a registered url") {
                var info: URLInfo? = nil
                var responseURL: NSURL? = nil
                
                router.get("/users/:id") { request in
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1")!) { (data, response, _) in
                    responseURL = response?.URL
                }.resume()
                
                expect(info?.components).toEventually(equal(["id" : "1"]))
                expect(info?.queryParameters).toEventually(equal([]))
                expect(responseURL?.absoluteString).toEventually(equal("http://www.test.com/users/1"))
            }
            
            it("should call the handler when requesting multiple registered urls") {
                var usersInfo: URLInfo? = nil
                var usersResponseURL: NSURL? = nil
                var usersCommentsInfo: URLInfo? = nil
                var usersCommentsResponseURL: NSURL? = nil
                
                router.get("/comments/:id") { request in
                    XCTFail("Shouldn't reach here")
                    usersInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                router.get("/users/:id") { request in
                    usersInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                router.get("/commentaries/:id") { request in
                    XCTFail("Shouldn't reach here")
                    usersInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                router.get("/users/:id/comments/:comment_id") { request in
                    usersCommentsInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                router.get("/users/:id/comments/:comment_id/whatever") { request in
                    XCTFail("Shouldn't reach here")
                    usersCommentsInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1")!) { (_, response, _) in
                    usersResponseURL = response?.URL
                }.resume()
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1/comments/2?page=2&author=hector")!) { (_, response, _) in
                    usersCommentsResponseURL = response?.URL
                }.resume()
                
                expect(usersInfo?.components).toEventually(equal(["id" : "1"]))
                expect(usersInfo?.queryParameters).toEventually(equal([]))
                expect(usersResponseURL?.absoluteString).toEventually(equal("http://www.test.com/users/1"))
                expect(usersCommentsInfo?.components).toEventually(equal(["id": "1", "comment_id": "2"]))
                expect(usersCommentsInfo?.queryParameters).toEventually(equal([NSURLQueryItem(name: "page", value: "2"), NSURLQueryItem(name: "author", value: "hector")]))
                expect(usersCommentsResponseURL?.absoluteString).toEventually(equal("http://www.test.com/users/1/comments/2?page=2&author=hector"))
            }
            
            context("when the Router has latency") {
                it("should delay the mocked response") {
                    var responseData: NSData? = nil
                    router.latency = 1.1
                    router.get("/users/:id") { request in
                        return ["test": "value"]
                    }
                    
                    NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1")!) { (data, response, _) in
                        responseData = data
                        }.resume()
                    
                    
                    let startTime = CFAbsoluteTimeGetCurrent()
                    expect(responseData).toNotEventually(beNil(), timeout: 1.5)
                    let endTime = CFAbsoluteTimeGetCurrent()
                    expect(endTime - startTime) >= 1.1
                }
                
                it("should not affect the latency of other routers") {
                    router.latency = 2.0
                    
                    var responseData: NSData? = nil
                    let router2 = Router.register("http://www.test2.com")
                    router2.get("/users/:id") { request in
                        return ["test": "value"]
                    }
                    
                    NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test2.com/users/1")!) { (data, response, _) in
                        responseData = data
                        }.resume()
                    
                    
                    let startTime = CFAbsoluteTimeGetCurrent()
                    expect(responseData).toNotEventually(beNil())
                    let endTime = CFAbsoluteTimeGetCurrent()
                    expect(endTime - startTime) <= 1.0
                }
            }
        }
        
        describe("Non registered urls") {
            var router: Router!
            
            beforeEach{
                router = Router.register("http://www.test.com")
            }
            
            it("should not call the handler when requesting a non registered url") {
                var info: URLInfo? = nil
                var responseURL: NSURL? = NSURL(string: "")
                var responseError: NSError? = NSError(domain: "", code: 1, userInfo: nil)
                
                router.get("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/userssssss/1")!) { (_, response, error) in
                    responseURL = response?.URL
                    responseError = error
                    }.resume()
                
                expect(info?.components).toEventually(beNil())
                expect(info?.queryParameters).toEventually(beNil())
                expect(responseURL?.host).toEventually(equal("www.test.com"))
                expect(responseError).toEventually(beNil())
            }
            
            it("should not call the handler when requesting a registered url but using a different HTTPMethod") {
                var info: URLInfo? = nil
                var responseURL: NSURL? = NSURL(string: "")
                var responseError: NSError? = NSError(domain: "", code: 1, userInfo: nil)
                
                router.del("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                let request = NSMutableURLRequest(URL: NSURL(string: "http://www.test.com/users/1")!)
                request.HTTPMethod = "PUT"
                NSURLSession.sharedSession().dataTaskWithRequest(request) { (_, response, error) in
                    responseURL = response?.URL
                    responseError = error
                    }.resume()
                
                expect(info).toEventually(beNil())
                expect(responseURL?.host).toEventually(equal("www.test.com"))
                expect(responseError).toEventually(beNil())
            }
        }
        
        describe("Request body") {
            var router: Router!
            
            beforeEach{
                router = Router.register("http://www.test.com")
            }
            
            it("should give back the body in the handler when a NSURLSession request has it") {
                var info: URLInfo? = nil
                var bodyData: NSData? = nil
                var bodyDictionary: NSDictionary? = nil
                
                let request = NSMutableURLRequest(URL: NSURL(string: "http://www.test.com/users/1")!)
                request.HTTPMethod = "POST"
                let params = ["username":"test", "password":"pass"] as Dictionary<String, String>
                request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(params, options: .PrettyPrinted)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                router.post("/users/:id") { request in
                    info = (components: request.components, queryParameters: request.queryParameters)
                    bodyData = request.HTTPBody
                    bodyDictionary = try! NSJSONSerialization.JSONObjectWithData(bodyData!, options: .MutableLeaves) as? NSDictionary
                    
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithRequest(request.copy() as! NSURLRequest){ (_, _, _) in }.resume()
                
                expect(info?.components).toEventually(equal(["id" : "1"]))
                expect(info?.queryParameters).toEventually(equal([]))
                expect(bodyData).toNotEventually(beNil())
                expect(bodyDictionary!["username"] as? String).toEventually(equal("test"))
                expect(bodyDictionary!["password"] as? String).toEventually(equal("pass"))
            }
            
            it("should give back the body in the handler when a NSURLConnection request has it") {
                var info: URLInfo? = nil
                var bodyData: NSData? = nil
                var bodyDictionary: NSDictionary? = nil
                
                let request = NSMutableURLRequest(URL: NSURL(string: "http://www.test.com/user_equipment/1")!)
                request.HTTPMethod = "PUT"
                let params = ["username":"manzo", "token":"power"] as Dictionary<String, String>
                request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(params, options: .PrettyPrinted)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                router.put("/user_equipment/:id") { request in
                    info = (components: request.components, queryParameters: request.queryParameters)
                    bodyData = request.HTTPBody
                    bodyDictionary = try! NSJSONSerialization.JSONObjectWithData(bodyData!, options: .MutableLeaves) as? NSDictionary
                    
                    return nil
                }
                
                let _ = NSURLConnection(request: request, delegate: nil)
                
                expect(info?.components).toEventually(equal(["id" : "1"]))
                expect(info?.queryParameters).toEventually(equal([]))
                expect(bodyData).toNotEventually(beNil())
                expect(bodyDictionary!["username"] as? String).toEventually(equal("manzo"))
                expect(bodyDictionary!["token"] as? String).toEventually(equal("power"))
            }
            
            it("should give back the HTTPHeaders in the handler when a NSURLSession request has it") {
                var contentType: String? = nil
                var accept: String? = nil
                
                let request = NSMutableURLRequest(URL: NSURL(string: "http://www.test.com/users/1")!)
                request.HTTPMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                router.post("/users/:id") { request in
                    contentType = request.HTTPHeaders!["Content-Type"]
                    accept = request.HTTPHeaders!["Accept"]
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithRequest(request){ (_, _, _) in }.resume()
                
                expect(contentType).toEventually(equal("application/json"))
                expect(accept).toEventually(equal("application/json"))
            }
            
            it("shouldn't give back HTTPHeaders in the handler when the request doesn't provide headers") {
                var count: Int? = nil
                
                let request = NSMutableURLRequest(URL: NSURL(string: "http://www.test.com/users/1")!)
                request.HTTPMethod = "POST"
                
                router.post("/users/:id") { request in
                    count = request.HTTPHeaders!.count
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithRequest(request){ (_, _, _) in }.resume()
                
                expect(count).toEventually(be(0))
            }
        }
        
        describe("Response objects") {
            var router: Router!
            
            beforeEach{
                router = Router.register("http://www.test.com")
            }
            
            context("default behaviors") {
                
                let url = NSURL(string: "http://www.test.com/users")!
                
                beforeEach{
                    router.get("/users"){ request in
                        return ["":""]
                    }
                }

                it("should return 200 status code") {
                    var statusCode: Int? = nil
                    
                    NSURLSession.sharedSession().dataTaskWithURL(url) { (_, response, _) in
                        let response = response as! NSHTTPURLResponse
                        statusCode = response.statusCode
                        }.resume()
                    
                    expect(statusCode).toEventually(equal(200))
                }
                
                it("should return the default header fields") {
                    var allHeaders: [String : String]? = nil
                    
                    NSURLSession.sharedSession().dataTaskWithURL(url) { (_, response, _) in
                        let response = response as! NSHTTPURLResponse
                        allHeaders = response.allHeaderFields as? [String : String]
                        }.resume()
                    
                    expect(allHeaders).toEventually(equal(["Content-Type": "application/json"]))
                }
            }
            
            it("should return the specified object when requesting a registered url") {
                db.create(User.self, number: 2)
                
                var responseDictionary: NSDictionary? = nil
                
                router.get("/users/:id"){ request in
                    return db.find(User.self, id: request.components["id"]!)
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1")!) { (data, response, _) in
                    responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
                    }.resume()
                
                expect(responseDictionary).toNotEventually(beNil())
                expect(responseDictionary?["id"] as? String).to(equal("1"))
            }
            
            it("should return the specified object and code inside a response object with code when requesting a registered url") {
                db.create(User.self, number: 20)
                
                var statusCode: Int? = nil
                var responseDictionary: NSDictionary? = nil
                
                router.get("/users/:id"){ request in
                    return Response(statusCode: 200, body: db.find(User.self, id: request.components["id"]!)!)
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/2")!) { (data, response, _) in
                    let response = response as! NSHTTPURLResponse
                    statusCode = response.statusCode
                    responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
                    }.resume()
                
                expect(responseDictionary?["firstName"]).toNotEventually(beNil())
                expect(responseDictionary?["id"] as? String).toEventually(equal("2"))
                expect(statusCode).toEventually(equal(200))
            }
            
            it("should return the specified error object and code inside a response object with code when requesting a registered url") {
                var statusCode: Int? = nil
                var dataLength = 10000
                
                router.get("/users/:id"){ request in
                    // Optional.Some("none") -> not valid JSON object
                    return Response(statusCode: 400, body: Optional.Some("none"))
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/2")!) { (data, response, _) in
                    let response = response as! NSHTTPURLResponse
                    statusCode = response.statusCode
                    dataLength = data!.length
                    }.resume()
                
                expect(dataLength).toEventually(equal(0))
                expect(statusCode).toEventually(equal(400))
            }
            
            it("should return the specified response headers inside a response object with code when requesting a registered url") {
                var allHeaders: [String : String]? = nil
                
                router.get("/users/:id"){ request in
                    return Response(statusCode: 400, body: ["id" : "foo", "type" : "User"], headerFields: ["access_token" : "094850348502", "user_id" : "124"])
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/2")!) { (data, response, _) in
                    let response = response as! NSHTTPURLResponse
                    allHeaders = response.allHeaderFields as? [String : String]
                    }.resume()

                expect(allHeaders?["access_token"]).toEventually(equal("094850348502"))
                expect(allHeaders?["user_id"]).toEventually(equal("124"))
                expect(allHeaders?["bar"]).toEventually(beNil())
            }
            
            it("should gets the response fields from custom response object adopting the ResponseFieldsProvider protocol") {
                var allHeaders: [String : String]? = nil
                var responseDictionary: NSDictionary? = nil
                var statusCode: Int? = nil
                
                router.get("/users/:id"){ request in
                    return CustomResponse(statusCode: 400, body: ["id" : 2], headerFields: ["access_token" : "094850348502"])
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/2")!) { (data, response, _) in
                    let response = response as! NSHTTPURLResponse
                    allHeaders = response.allHeaderFields as? [String : String]
                    responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
                    statusCode = response.statusCode
                    }.resume()
                
                expect(allHeaders?["access_token"]).toEventually(equal("094850348502"))
                expect(statusCode).toEventually(equal(400))
                expect(responseDictionary?["id"]).toEventually(be(2))
            }
            
            it("should return the specified array of objects when requesting a registered url") {
                db.create(User.self, number: 20)
                
                var responseArray: NSArray? = nil
                
                router.get("/users"){ request in
                    return db.findAll(User)
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users")!) { (data, response, _) in
                    responseArray = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSArray
                    }.resume()
                
                expect(responseArray?.count).toEventually(equal(20))
                expect(responseArray?.firstObject?["firstName"]).toNotEventually(beNil())
                expect(responseArray?.firstObject?["id"]).toEventually(equal("0"))
                expect(responseArray?[14]["id"]).toEventually(equal("14"))
                expect(responseArray?.lastObject?["id"]).toEventually(equal("19"))
            }
            
            it("should return nil for objects not serializable to JSON") {
                router.get("/nothing/:id"){ request in
                    return Optional.Some("none")
                }
                
                var called = false
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/nothing/1")!) { (data, response, _) in
                    called = true
                    expect(data?.length).to(equal(0))
                }.resume()
                
                expect(called).toEventually(beTrue())
            }
        }
        
        describe("Multiple Routers") {
            var router: Router!
            
            it("Should handle multiple Routers that register different URLs") {
                router = Router.register("http://www.test.com")
                
                var info: URLInfo? = nil
                var responseURL: NSURL? = nil
                
                var secondInfo: URLInfo? = nil
                var secondResponseURL: NSURL? = nil
                let secondRouter = Router.register("www.host2.com")
                
                router.get("/users/:id") { request in
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                secondRouter.get("/messages/:user") { request in
                    secondInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1")!) { (data, response, _) in
                    responseURL = response?.URL
                    }.resume()
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.host2.com/messages/24")!) { (data, response, _) in
                    secondResponseURL = response?.URL
                    }.resume()
                
                expect(info?.components).toEventually(equal(["id" : "1"]))
                expect(info?.queryParameters).toEventually(equal([]))
                expect(responseURL?.absoluteString).toEventually(equal("http://www.test.com/users/1"))
                
                expect(secondInfo?.components).toEventually(equal(["user" : "24"]))
                expect(secondInfo?.queryParameters).toEventually(equal([]))
                expect(secondResponseURL?.absoluteString).toEventually(equal("http://www.host2.com/messages/24"))
            }
            
            it("Should manage which Router has to be selected when registering routes with similar baseURL") {
                var responseURL: NSURL? = nil
                var components: [String : String]? = nil
                router = Router.register("http://www.test.com")
                let secondRouter = Router.register("http://www.test.com/v1")
                let thirdRouter = Router.register("http://www.test.com/v1/foo/bar")
                var isReached: Bool?
                
                router.get("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    components = request.components
                    return nil
                }
                
                secondRouter.get("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    components = request.components
                    return nil
                }
                
                thirdRouter.get("/users/:id") { request in
                    isReached = true
                    components = request.components
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/v1/foo/bar/users/1")!) { (data, response, _) in
                    responseURL = response?.URL
                    }.resume()
                
                expect(isReached).toEventually(beTrue())
                expect(components).toEventually(equal(["id" : "1"]))
                expect(responseURL?.absoluteString).toEventually(equal("http://www.test.com/v1/foo/bar/users/1"))
            }
            
            it("Should manage which Router has to be selected when registering routes with same baseURL") {
                router = Router.register("http://www.test.com")
                let secondRouter = Router.register("http://www.test.com")
                let thirdRouter = Router.register("http://www.test.com")
                var isReached: Bool?
                var responseURL: NSURL? = nil
                var components: [String : String]? = nil
                
                router.get("/users/:user_id/comments/:comment_id") { request in
                    isReached = true
                    components = request.components
                    return nil
                }
                
                secondRouter.get("/users/:id") { request in
                    components = request.components
                    return nil
                }
                
                thirdRouter.get("/users/:id/comments") { request in
                    components = request.components
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1/comments/2")!) { (data, response, _) in
                    responseURL = response?.URL
                    }.resume()
                
                expect(isReached).toEventually(beTrue())
                expect(components).toEventually(equal(["user_id" : "1", "comment_id" : "2"]))
                expect(responseURL?.absoluteString).toEventually(equal("http://www.test.com/users/1/comments/2"))
            }
            
            it("Should properly handle multiple registered and unregistered Routers that register different URLs") {
                router = Router.register("http://www.test.com")
                
                var info: URLInfo? = nil
                var responseURL: NSURL? = nil
                
                var secondInfo: URLInfo? = nil
                var secondResponseURL: NSURL? = nil
                let secondRouter = Router.register("www.host2.com")
                
                var thirdInfo: URLInfo? = nil
                var thirdResponseURL: NSURL? = nil
                let thirdRouter = Router.register("www.another.com")
                
                router.get("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                secondRouter.get("/messages/:user") { request in
                    secondInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                thirdRouter.get("/sessions/:global_id") { request in
                    XCTFail("Shouldn't reach here")
                    thirdInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                Router.unregister("http://www.test.com")
                Router.unregister("www.another.com")
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1")!) { (data, response, _) in
                    responseURL = response?.URL
                    }.resume()
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.host2.com/messages/24")!) { (data, response, _) in
                    secondResponseURL = response?.URL
                    }.resume()
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.another.com/sessions/55")!) { (data, response, _) in
                    thirdResponseURL = response?.URL
                    }.resume()
                
                expect(info).toEventually(beNil())
                expect(responseURL?.host).toEventually(equal("www.test.com"))
                
                expect(secondInfo?.components).toEventually(equal(["user" : "24"]))
                expect(secondInfo?.queryParameters).toEventually(equal([]))
                expect(secondResponseURL?.absoluteString).toEventually(equal("http://www.host2.com/messages/24"))
                
                expect(thirdInfo).toEventually(beNil())
                expect(thirdResponseURL?.host).toEventually(equal("www.another.com"))
            }
            
            it("Should fail when not properly registering Routers") {
                router = Router.register("http://www.test.com")
                
                var info: URLInfo? = nil
                var responseURL: NSURL? = nil
                let _ = Router.register("http://www.host2.com")
                
                router.get("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.host2.com/users/1")!) { (data, response, _) in
                    responseURL = response?.URL
                    }.resume()
                
                expect(info).toEventually(beNil())
                expect(responseURL?.host).toEventually(equal("www.host2.com"))
            }
            
            it("Should not respond any request on any Router when disabling the server") {
                router = Router.register("http://www.test.com")
                
                var info: URLInfo? = nil
                var responseURL: NSURL? = nil
                
                var secondInfo: URLInfo? = nil
                var secondResponseURL: NSURL? = nil
                let secondRouter = Router.register("www.host2.com")
                
                var thirdInfo: URLInfo? = nil
                var thirdResponseURL: NSURL? = nil
                let thirdRouter = Router.register("www.another.com")
                
                router.get("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                secondRouter.get("/messages/:user") { request in
                    XCTFail("Shouldn't reach here")
                    secondInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                thirdRouter.get("/sessions/:global_id") { request in
                    XCTFail("Shouldn't reach here")
                    thirdInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                Router.disableAll()
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1")!) { (data, response, _) in
                    responseURL = response?.URL
                    }.resume()
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.host2.com/messages/24")!) { (data, response, _) in
                    secondResponseURL = response?.URL
                    }.resume()
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.another.com/sessions/55")!) { (data, response, _) in
                    thirdResponseURL = response?.URL
                    }.resume()
                
                expect(info).toEventually(beNil())
                expect(responseURL?.host).toEventually(equal("www.test.com"))
                
                expect(secondInfo).toEventually(beNil())
                expect(secondResponseURL?.host).toEventually(equal("www.host2.com"))
                
                expect(thirdInfo).toEventually(beNil())
                expect(thirdResponseURL?.host).toEventually(equal("www.another.com"))
            }
            
            it("should not leak any router when router gets disabled or unregistered") {
                weak var router1: Router? = Router.register("www.host1.com")
                weak var router2: Router? = Router.register("www.host2.com")
                weak var router3: Router? = Router.register("www.host3.com")
                weak var router4: Router? = Router.register("www.host4.com")
                
                expect(router1).toNot(beNil())
                expect(router2).toNot(beNil())
                expect(router3).toNot(beNil())
                expect(router4).toNot(beNil())
                
                Router.unregister("www.host2.com")
                Router.unregister("www.host4.com")
                
                expect(router1).toNot(beNil())
                expect(router2).to(beNil())
                expect(router3).toNot(beNil())
                expect(router4).to(beNil())
                
                Router.disableAll()
                
                expect(router1).to(beNil())
                expect(router2).to(beNil())
                expect(router3).to(beNil())
                expect(router4).to(beNil())
            }
        }
        
        describe("Popular networking libraries compatibility") {
            var router: Router!
            var response: [String: String]? = nil
            let url = NSURL(string: "http://kakapotest.com/users/1")!
            let configuration: NSURLSessionConfiguration = {
                let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
                configuration.protocolClasses = [KakapoServer.self]
                return configuration
            }()
            
            beforeEach{
                response = nil
                router = Router.register("http://kakapotest.com")
                router.get("/users/:id") { request in
                    return ["fine": "true"]
                }
            }
            
            it("should intercept AFNetworking requests") {
                let manager = AFURLSessionManager(sessionConfiguration: configuration)
                let request = NSURLRequest(URL: url)
                manager.dataTaskWithRequest(request) { (_, responseObject, _) in
                    response = responseObject as? [String: String]
                }.resume()
                
                expect(response).toNotEventually(beNil())
                expect(response).to(equal(["fine": "true"]))
            }
            
            it("should intercept Alamofire requests") {
                let manager = Manager(configuration: configuration)
                let request = NSURLRequest(URL: url)
                manager.request(request).responseJSON { (responseObject) in
                    response = responseObject.result.value as? [String: String]
                    }
                
                expect(response).toNotEventually(beNil())
                expect(response).to(equal(["fine": "true"]))
            }
        }
    }
}