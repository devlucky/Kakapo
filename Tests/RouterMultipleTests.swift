//
//  RouterMultipleTests.swift
//  Kakapo
//
//  Copyright © 2018 devlucky. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Kakapo

class RouterMultipleTests: QuickSpec {

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
                var components: [String: String]? = nil
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
                var components: [String: String]? = nil

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
