//
//  RouterURLRegistrationTests.swift
//  Kakapo
//
//  Copyright © 2018 devlucky. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Kakapo

class RouterURLRegistrationTests: QuickSpec {

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
    }
}
