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
    let headerFields: [String: String]?
    
    init(statusCode: Int, body: Serializable, headerFields: [String: String]? = nil) {
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
                    var allHeaders: [String: String]? = nil
                    
                    URLSession.shared.dataTask(with: url) { (_, response, _) in
                        let response = response as! HTTPURLResponse
                        allHeaders = response.allHeaderFields as? [String: String]
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
                var allHeaders: [String: String]? = nil
                
                router.get("/users/:id") { _ in
                    let body = ["id": "foo", "type": "User"]
                    let headerFields = ["access_token": "094850348502", "user_id": "124"]
                    return Response(statusCode: 400, body: body, headerFields: headerFields)
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/2")!) { (_, response, _) in
                    let response = response as! HTTPURLResponse
                    allHeaders = response.allHeaderFields as? [String: String]
                    }.resume()

                expect(allHeaders?["access_token"]).toEventually(equal("094850348502"))
                expect(allHeaders?["user_id"]).toEventually(equal("124"))
                expect(allHeaders?["bar"]).toEventually(beNil())
            }
            
            it("should gets the response fields from custom response object adopting the ResponseFieldsProvider protocol") {
                var allHeaders: [String: String]? = nil
                var responseDictionary: [String: AnyObject]?
                var statusCode: Int? = nil
                
                router.get("/users/:id") { _ in
                    return CustomResponse(statusCode: 400, body: ["id": 2], headerFields: ["access_token": "094850348502"])
                }
                
                URLSession.shared.dataTask(with: URL(string: "http://www.test.com/users/2")!) { (data, response, _) in
                    let response = response as! HTTPURLResponse
                    allHeaders = response.allHeaderFields as? [String: String]
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
    }
}
