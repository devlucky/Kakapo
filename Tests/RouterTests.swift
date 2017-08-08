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

@testable import Kakapo

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

        var store = Store()
        
        beforeEach {
            RouterTestServer.register()
            store = Store()
        }
        
        afterEach {
            RouterTestServer.disable()
            Router.disableAll()
        }

        describe("Cancelling requests") {
            var router: Router!
            let baseURL = "http://www.funky-cancel-request.com"
            let latency: TimeInterval = 0.03

            beforeEach {
                router = Router.register(baseURL)
                router.latency = latency // latency > 0 to allow us to stop the request before execution
            }

            it("should mark a request as cancelled") {
                var responseError: Error? = nil

                router.get("/foobar/:id") { _ in
                    XCTFail("Request should get cancelled before execution")
                    return nil
                }

                let requestURL = URL(string: "\(baseURL)/foobar/1")!

                let dataTask = URLSession.shared.dataTask(with: requestURL) { (_, _, error) in
                    responseError = error
                }

                dataTask.resume()
                dataTask.cancel()

                expect(responseError).toNotEventually(beNil(), timeout: (latency + 1))
                expect(responseError?.localizedDescription).toEventually(equal("cancelled"), timeout: (latency + 1))
            }

            it("should not confuse multiple request with identical URL") {
                var response_A: Any? = nil
                var responseError_B: Error? = nil
                let canceledRequestID = "999"

                router.get("/cash/:id") { request in
                    let paramID = request.components["id"]
                    if paramID == canceledRequestID {
                        XCTFail("Cancelled request should not get executed")
                    }
                    return ["foo": "bar"]
                }

                let requestURL_A = URL(string: "\(baseURL)/cash/333")!
                let requestURL_B = URL(string: "\(baseURL)/cash/\(canceledRequestID)")!

                let dataTask_A = URLSession.shared.dataTask(with: requestURL_A) { (_, response, _) in
                    response_A = response
                }
                let dataTask_B = URLSession.shared.dataTask(with: requestURL_B) { (_, _, error) in
                    responseError_B = error
                }

                dataTask_A.resume()
                dataTask_B.resume()
                dataTask_B.cancel() // cancel immediately -> should never get executed, because of Router.latency

                // expect task A to succeed
                expect(response_A).toNotEventually(beNil(), timeout: (latency + 1))

                // expect task B to get cancelled
                expect(responseError_B).toNotEventually(beNil(), timeout: (latency + 1))
                expect(responseError_B?.localizedDescription).toEventually(equal("cancelled"), timeout: (latency + 1))
            }

            it("should send notifications when loading has finished") {

                router.get("/epic-fail/:id") { _ in
                    XCTFail("Expected that request, which has been marked as 'cancelled', not to be executed")
                    return nil
                }

                let requestURL = URL(string: "\(baseURL)/epic-fail/1")!

                /*
                Note: we need to manually create a Server instance here to test the stopping logic, because
                      usually the Server instances are automatically created by the operating system.
                      And there's no way for us to access these automatically created instances from the Router.
                      Therefore we simulate the "stopLoading" and "startLoading" mechanism manually.
                */
                let urlRequest = URLRequest(url: requestURL)
                let client = FakeURLProtocolClient()
                let server = Server(request: urlRequest, cachedResponse: nil, client: client)

                server.stopLoading()
                expect(server.requestCancelled).to(beTrue())
                server.startLoading() // this should not trigger the "/epic-fail/:id" router request (see XCTFail above)
            }
        }

        describe("Registering urls") {
            var router: Router!
            
            beforeEach {
                router = Router.register("http://www.test.com")
            }
            
            context("when the Router is initialized") {
                it("should not have latency") {
                    expect(router.latency) == 0
                }
            }
            
            it("should call the handler when requesting a registered url") {
                var info: URLInfo? = nil
                var responseURL: URL? = nil
                
                router.get("/users/:id") { request in
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/1")!) { (_, response, _) in
                    responseURL = response?.url
                }.resume()
                
                expect(info?.components).toEventually(equal(["id": "1"]))
                expect(info?.queryParameters).toEventually(equal([]))
                expect(responseURL?.absoluteString).toEventually(equal("http://www.test.com/users/1"))
            }
            
            it("should call the handler when requesting multiple registered urls") {
                var usersInfo: URLInfo? = nil
                var usersResponseURL: URL? = nil
                var usersCommentsInfo: URLInfo? = nil
                var usersCommentsResponseURL: URL? = nil
                
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
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/1")!) { (_, response, _) in
                    usersResponseURL = response?.url
                }.resume()
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/1/comments/2?page=2&author=hector")!) { (_, response, _) in
                    usersCommentsResponseURL = response?.url
                }.resume()
                
                expect(usersInfo?.components).toEventually(equal(["id": "1"]))
                expect(usersInfo?.queryParameters).toEventually(equal([]))
                expect(usersResponseURL?.absoluteString).toEventually(equal("http://www.test.com/users/1"))
                expect(usersCommentsInfo?.components).toEventually(equal(["id": "1", "comment_id": "2"]))
                expect(usersCommentsInfo?.queryParameters).toEventually(equal([URLQueryItem(name: "page", value: "2"), URLQueryItem(name: "author", value: "hector")]))
                expect(usersCommentsResponseURL?.absoluteString).toEventually(equal("http://www.test.com/users/1/comments/2?page=2&author=hector"))
            }
            
            it("should call handlers with same path but different http methods") {
                var calledPost = false
                var calledPut = false
                var calledDel = false
                var calledPatch = false
                
                router.post("/users/:user_id") { (_) -> Serializable? in
                    calledPost = true
                    return nil
                }
                
                router.put("/users/:user_id") { (_) -> Serializable? in
                    calledPut = true
                    return nil
                }
                
                router.del("/users/:user_id") { (_) -> Serializable? in
                    calledDel = true
                    return nil
                }

                router.patch("/users/:user_id") { (_) -> Serializable? in
                    calledPatch = true
                    return nil
                }

                var request = URLRequest(url: URL(string: "http://www.test.com/users/1")!)
                request.httpMethod = "POST"
                URLSession.shared.dataTask(with: request) { (_, _, _) in }.resume()
                
                expect(calledPost).toEventually(beTrue())
                
                request = URLRequest(url: URL(string: "http://www.test.com/users/1")!)
                request.httpMethod = "PUT"
                URLSession.shared.dataTask(with: request) { (_, _, _) in }.resume()
                
                expect(calledPut).toEventually(beTrue())
                
                request = URLRequest(url: URL(string: "http://www.test.com/users/1")!)
                request.httpMethod = "DELETE"
                URLSession.shared.dataTask(with: request) { (_, _, _) in }.resume()
                
                expect(calledDel).toEventually(beTrue())

                request = URLRequest(url: URL(string: "http://www.test.com/users/1")!)
                request.httpMethod = "PATCH"
                URLSession.shared.dataTask(with: request) { (_, _, _) in }.resume()

                expect(calledPatch).toEventually(beTrue())
            }

            it("should replace handlers with same path and http methods") {
                var calledFirstPost = false
                var calledSecondPost = false
                
                router.post("/users/:user_id") { (_) -> Serializable? in
                    calledFirstPost = true
                    return nil
                }
                
                var request = URLRequest(url: URL(string: "http://www.test.com/users/1")!)
                request.httpMethod = "POST"
                URLSession.shared.dataTask(with: request) { (_, _, _) in }.resume()
                
                expect(calledFirstPost).toEventually(beTrue())
                
                router.post("/users/:user_id") { (_) -> Serializable? in
                    calledSecondPost = true
                    return nil
                }
                
                URLSession.shared.dataTask(with: request) { (_, _, _) in }.resume()
                
                expect(calledSecondPost).toEventually(beTrue())
            }
            
            context("when the Router has latency") {
                it("should delay the mocked response") {
                    var responseData: Data? = nil
                    router.latency = 1.1
                    router.get("/users/:id") { _ in
                        return ["test": "value"]
                    }
                    
                    URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/1")!) { (data, _, _) in
                        responseData = data
                        }.resume()
                    
                    let startTime = CFAbsoluteTimeGetCurrent()
                    expect(responseData).toNotEventually(beNil(), timeout: 1.5)
                    let endTime = CFAbsoluteTimeGetCurrent()
                    expect(endTime - startTime) >= 1.1
                }
                
                it("should not affect the latency of other routers") {
                    router.latency = 2.0
                    
                    var responseData: Data? = nil
                    let router2 = Router.register("http://www.test2.com")
                    router2.get("/users/:id") { _ in
                        return ["test": "value"]
                    }
                    
                    URLSession.shared.dataTask(with: URL(string: "http://www.test2.com/users/1")!) { (data, _, _) in
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
            
            beforeEach {
                router = Router.register("http://www.test.com")
            }
            
            it("should not call the handler when requesting a non registered url") {
                var info: URLInfo? = nil
                var responseURL: URL? = URL(string: "")
                var responseError: Error? = NSError(domain: "", code: 1, userInfo: nil)
                
                router.get("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/userssssss/1")!) { (_, response, error) in
                    responseURL = response?.url
                    responseError = error
                    }.resume()
                
                expect(info?.components).toEventually(beNil())
                expect(info?.queryParameters).toEventually(beNil())
                expect(responseURL?.host).toEventually(equal("www.test.com"))
                expect(responseError).toEventually(beNil())
            }
            
            it("should not call the handler when requesting a registered url but using a different HTTPMethod") {
                var info: URLInfo? = nil
                var responseURL: URL? = URL(string: "")
                var responseError: Error? = NSError(domain: "", code: 1, userInfo: nil)
                
                router.del("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                var request = URLRequest(url: URL(string: "http://www.test.com/users/1")!)
                request.httpMethod = "PUT"
                URLSession.shared.dataTask(with: request) { (_, response, error) in
                    responseURL = response?.url
                    responseError = error
                    }.resume()
                
                expect(info).toEventually(beNil())
                expect(responseURL?.host).toEventually(equal("www.test.com"))
                expect(responseError).toEventually(beNil())
            }
        }
        
        describe("Request body") {
            var router: Router!
            
            beforeEach {
                router = Router.register("http://www.test.com")
            }
            
            it("should give back the body in the handler when a URLSession request has it") {
                var info: URLInfo? = nil
                var bodyData: Data? = nil
                var bodyDictionary: [String: AnyObject]?
                
                var request = URLRequest(url: URL(string: "http://www.test.com/users/1")!)
                request.httpMethod = "POST"
                let params = ["username": "test", "password": "pass"]
                request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                router.post("/users/:id") { request in
                    info = (components: request.components, queryParameters: request.queryParameters)
                    bodyData = request.httpBody
                    bodyDictionary = try! JSONSerialization.jsonObject(with: bodyData!, options: .mutableLeaves) as? [String: AnyObject]
                    
                    return nil
                }
                
                URLSession.shared.dataTask(with: request) { (_, _, _) in }.resume()
                
                expect(info?.components).toEventually(equal(["id": "1"]))
                expect(info?.queryParameters).toEventually(equal([]))
                expect(bodyData).toNotEventually(beNil())
                expect(bodyDictionary!["username"] as? String).toEventually(equal("test"))
                expect(bodyDictionary!["password"] as? String).toEventually(equal("pass"))
            }
            
            it("should give back the body in the handler when a URLConnection request has it") {
                var info: URLInfo? = nil
                var bodyData: Data? = nil
                var bodyDictionary: [String: AnyObject]?
                
                var request = URLRequest(url: URL(string: "http://www.test.com/user_equipment/1")!)
                request.httpMethod = "PUT"
                let params = ["username": "manzo", "token": "power"]
                request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                router.put("/user_equipment/:id") { request in
                    info = (components: request.components, queryParameters: request.queryParameters)
                    bodyData = request.httpBody
                    bodyDictionary = try! JSONSerialization.jsonObject(with: bodyData!, options: .mutableLeaves) as? Dictionary
                    
                    return nil
                }
                
                _ = NSURLConnection(request: request, delegate: nil)
                
                expect(info?.components).toEventually(equal(["id": "1"]))
                expect(info?.queryParameters).toEventually(equal([]))
                expect(bodyData).toNotEventually(beNil())
                expect(bodyDictionary!["username"] as? String).toEventually(equal("manzo"))
                expect(bodyDictionary!["token"] as? String).toEventually(equal("power"))
            }
            
            it("should give back the httpHeaders in the handler when a URLSession request has it") {
                var contentType: String? = nil
                var accept: String? = nil
                
                var request = URLRequest(url: URL(string: "http://www.test.com/users/1")!)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                router.post("/users/:id") { request in
                    contentType = request.httpHeaders!["Content-Type"]
                    accept = request.httpHeaders!["Accept"]
                    return nil
                }
                
                URLSession.shared.dataTask(with: request) { (_, _, _) in }.resume()
                
                expect(contentType).toEventually(equal("application/json"))
                expect(accept).toEventually(equal("application/json"))
            }
            
            it("shouldn't give back httpHeaders in the handler when the request doesn't provide headers") {
                var count: Int? = nil
                
                var request = URLRequest(url: URL(string: "http://www.test.com/users/1")!)
                request.httpMethod = "POST"
                
                router.post("/users/:id") { request in
                    count = request.httpHeaders!.count
                    return nil
                }
                
                URLSession.shared.dataTask(with: request) { (_, _, _) in }.resume()
                
                expect(count).toEventually(equal(0))
            }
        }
        
        describe("Response objects") {
            var router: Router!
            
            beforeEach {
                router = Router.register("http://www.test.com")
            }
            
            context("default behaviors") {
                
                let url = URL(string: "http://www.test.com/users")!
                
                beforeEach {
                    router.get("/users") { _ in
                        return ["": ""]
                    }
                }

                it("should return 200 status code") {
                    var statusCode: Int? = nil
                    
                    URLSession.shared.dataTask(with: url) { (_, response, _) in
                        let response = response as! HTTPURLResponse
                        statusCode = response.statusCode
                        }.resume()
                    
                    expect(statusCode).toEventually(equal(200))
                }
                
                it("should return the default header fields") {
                    var allHeaders: [String : String]? = nil
                    
                    URLSession.shared.dataTask(with: url) { (_, response, _) in
                        let response = response as! HTTPURLResponse
                        allHeaders = response.allHeaderFields as? [String : String]
                        }.resume()
                    
                    expect(allHeaders).toEventually(equal(["Content-Type": "application/json"]))
                }
            }
            
            it("should return the specified object when requesting a registered url") {
                store.create(User.self, number: 2)
                
                var responseDictionary: [String: AnyObject]?
                
                router.get("/users/:id") { request in
                    return store.find(User.self, id: request.components["id"]!)
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/1")!) { (data, _, _) in
                    responseDictionary = try! JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? [String: AnyObject]
                    }.resume()
                
                expect(responseDictionary).toNotEventually(beNil())
                expect(responseDictionary?["id"] as? String).to(equal("1"))
            }
            
            it("should return the specified object and code inside a response object with code when requesting a registered url") {
                store.create(User.self, number: 20)
                
                var statusCode: Int? = nil
                var responseDictionary: [String: AnyObject]?
                
                router.get("/users/:id") { request in
                    return Response(statusCode: 200, body: store.find(User.self, id: request.components["id"]!)!)
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/2")!) { (data, response, _) in
                    let response = response as! HTTPURLResponse
                    statusCode = response.statusCode
                    responseDictionary = try! JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? [String: AnyObject]
                    }.resume()
                
                expect(responseDictionary?["firstName"]).toNotEventually(beNil())
                expect(responseDictionary?["id"] as? String).toEventually(equal("2"))
                expect(statusCode).toEventually(equal(200))
            }
            
            it("should return the specified error object and code inside a response object with code when requesting a registered url") {
                var statusCode: Int? = nil
                var dataLength = 10000
                
                router.get("/users/:id") { _ in
                    // Optional.some("none") -> not valid JSON object
                    return Response(statusCode: 400, body: Optional.some("none"))
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/2")!) { (data, response, _) in
                    let response = response as! HTTPURLResponse
                    statusCode = response.statusCode
                    dataLength = data!.count
                    }.resume()
                
                expect(dataLength).toEventually(equal(0))
                expect(statusCode).toEventually(equal(400))
            }
            
            it("should return the specified response headers inside a response object with code when requesting a registered url") {
                var allHeaders: [String : String]? = nil
                
                router.get("/users/:id") { _ in
                    let body = ["id": "foo", "type": "User"]
                    let headerFields = ["access_token": "094850348502", "user_id": "124"]
                    return Response(statusCode: 400, body: body, headerFields: headerFields)
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/2")!) { (_, response, _) in
                    let response = response as! HTTPURLResponse
                    allHeaders = response.allHeaderFields as? [String : String]
                    }.resume()

                expect(allHeaders?["access_token"]).toEventually(equal("094850348502"))
                expect(allHeaders?["user_id"]).toEventually(equal("124"))
                expect(allHeaders?["bar"]).toEventually(beNil())
            }
            
            it("should gets the response fields from custom response object adopting the ResponseFieldsProvider protocol") {
                var allHeaders: [String : String]? = nil
                var responseDictionary: [String: AnyObject]?
                var statusCode: Int? = nil
                
                router.get("/users/:id") { _ in
                    return CustomResponse(statusCode: 400, body: ["id": 2], headerFields: ["access_token": "094850348502"])
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/2")!) { (data, response, _) in
                    let response = response as! HTTPURLResponse
                    allHeaders = response.allHeaderFields as? [String : String]
                    responseDictionary = try! JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? [String: AnyObject]
                    statusCode = response.statusCode
                    }.resume()
                
                expect(allHeaders?["access_token"]).toEventually(equal("094850348502"))
                expect(statusCode).toEventually(equal(400))
                expect(responseDictionary?["id"] as? Int).toEventually(equal(2))
            }
            
            it("should return the specified array of objects when requesting a registered url") {
                store.create(User.self, number: 20)
                
                var responseArray: [[String: AnyObject]]? = nil
                
                router.get("/users") { _ in
                    return store.findAll(User.self)
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users")!) { (data, _, _) in
                    responseArray = try! JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? [[String: AnyObject]]
                    }.resume()
                
                expect(responseArray?.count).toEventually(equal(20))
                expect(responseArray?.first).toNotEventually(beNil())
                
                let first = responseArray!.first!
                expect(first["firstName"]).toNot(beNil())
                expect(first["id"] as? String) == "0"
                expect(responseArray?[14]["id"] as? String) == "14"
                expect(responseArray?.last?["id"] as? String) == "19"
            }
            
            it("should return nil for objects not serializable to JSON") {
                router.get("/nothing/:id") { _ in
                    return Optional.some("none")
                }
                
                var called = false
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/nothing/1")!) { (data, _, _) in
                    called = true
                    expect(data?.count).to(equal(0))
                }.resume()
                
                expect(called).toEventually(beTrue())
            }
        }
        
        describe("Multiple Routers") {
            var router: Router!
            
            it("Should handle multiple Routers that register different URLs") {
                router = Router.register("http://www.test.com")
                
                var info: URLInfo? = nil
                var responseURL: URL? = nil
                
                var secondInfo: URLInfo? = nil
                var secondResponseURL: URL? = nil
                let secondRouter = Router.register("www.host2.com")
                
                router.get("/users/:id") { request in
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                secondRouter.get("/messages/:user") { request in
                    secondInfo = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/1")!) { (_, response, _) in
                    responseURL = response?.url
                    }.resume()
                
                URLSession.shared.dataTask(with: URL(string: "http://www.host2.com/messages/24")!) { (_, response, _) in
                    secondResponseURL = response?.url
                    }.resume()
                
                expect(info?.components).toEventually(equal(["id": "1"]))
                expect(info?.queryParameters).toEventually(equal([]))
                expect(responseURL?.absoluteString).toEventually(equal("http://www.test.com/users/1"))
                
                expect(secondInfo?.components).toEventually(equal(["user": "24"]))
                expect(secondInfo?.queryParameters).toEventually(equal([]))
                expect(secondResponseURL?.absoluteString).toEventually(equal("http://www.host2.com/messages/24"))
            }
            
            it("Should manage which Router has to be selected when registering routes with similar baseURL") {
                var responseURL: URL? = nil
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
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/v1/foo/bar/users/1")!) { (_, response, _) in
                    responseURL = response?.url
                    }.resume()
                
                expect(isReached).toEventually(beTrue())
                expect(components).toEventually(equal(["id": "1"]))
                expect(responseURL?.absoluteString).toEventually(equal("http://www.test.com/v1/foo/bar/users/1"))
            }
            
            it("Should manage which Router has to be selected when registering routes with same baseURL") {
                router = Router.register("http://www.test.com")
                let secondRouter = Router.register("http://www.test.com")
                let thirdRouter = Router.register("http://www.test.com")
                var isReached: Bool?
                var responseURL: URL? = nil
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
                
                let url = URL(string: "http://www.test.com/users/1/comments/2")!
                URLSession.shared.dataTask(with: url) { (_, response, _) in
                    responseURL = response?.url
                    }.resume()
                
                expect(isReached).toEventually(beTrue())
                expect(components).toEventually(equal(["user_id": "1", "comment_id": "2"]))
                expect(responseURL?.absoluteString).toEventually(equal("http://www.test.com/users/1/comments/2"))
            }
            
            it("Should properly handle multiple registered and unregistered Routers that register different URLs") {
                router = Router.register("http://www.test.com")
                
                var info: URLInfo? = nil
                var responseURL: URL? = nil
                
                var secondInfo: URLInfo? = nil
                var secondResponseURL: URL? = nil
                let secondRouter = Router.register("www.host2.com")
                
                var thirdInfo: URLInfo? = nil
                var thirdResponseURL: URL? = nil
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
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/1")!) { (_, response, _) in
                    responseURL = response?.url
                    }.resume()
                
                URLSession.shared.dataTask(with: URL(string: "http://www.host2.com/messages/24")!) { (_, response, _) in
                    secondResponseURL = response?.url
                    }.resume()
                
                URLSession.shared.dataTask(with: URL(string: "http://www.another.com/sessions/55")!) { (_, response, _) in
                    thirdResponseURL = response?.url
                    }.resume()
                
                expect(info).toEventually(beNil())
                expect(responseURL?.host).toEventually(equal("www.test.com"))
                
                expect(secondInfo?.components).toEventually(equal(["user": "24"]))
                expect(secondInfo?.queryParameters).toEventually(equal([]))
                expect(secondResponseURL?.absoluteString).toEventually(equal("http://www.host2.com/messages/24"))
                
                expect(thirdInfo).toEventually(beNil())
                expect(thirdResponseURL?.host).toEventually(equal("www.another.com"))
            }
            
            it("Should fail when not properly registering Routers") {
                router = Router.register("http://www.test.com")
                
                var info: URLInfo? = nil
                var responseURL: URL? = nil
                _ = Router.register("http://www.host2.com")
                
                router.get("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    info = (components: request.components, queryParameters: request.queryParameters)
                    return nil
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.host2.com/users/1")!) { (_, response, _) in
                    responseURL = response?.url
                    }.resume()
                
                expect(info).toEventually(beNil())
                expect(responseURL?.host).toEventually(equal("www.host2.com"))
            }
            
            it("Should not respond any request on any Router when disabling the server") {
                router = Router.register("http://www.test.com")
                
                var info: URLInfo? = nil
                var responseURL: URL? = nil
                
                var secondInfo: URLInfo? = nil
                var secondResponseURL: URL? = nil
                let secondRouter = Router.register("www.host2.com")
                
                var thirdInfo: URLInfo? = nil
                var thirdResponseURL: URL? = nil
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
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/1")!) { (_, response, _) in
                    responseURL = response?.url
                    }.resume()
                
                URLSession.shared.dataTask(with: URL(string: "http://www.host2.com/messages/24")!) { (_, response, _) in
                    secondResponseURL = response?.url
                    }.resume()
                
                URLSession.shared.dataTask(with: URL(string: "http://www.another.com/sessions/55")!) { (_, response, _) in
                    thirdResponseURL = response?.url
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
    }
}
