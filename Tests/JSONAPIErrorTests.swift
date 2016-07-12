//
//  JSONAPIErrorTests.swift
//  Kakapo
//
//  Created by Alex Manzella on 26/06/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

import Quick
import Nimble
import SwiftyJSON
@testable import Kakapo

class JSONAPIErrorsSpec: QuickSpec {
    
    private struct ErrorDescription: Serializable {
        let description: String
    }

    override func spec() {
        
        func json(object: Serializable) -> JSON {
            return JSON(object.serialize()!)
        }
        
        describe("JSONAPIError") {
            
            it("should serialize the error") {
                let error = JSONAPIError(statusCode: 404) { (error) in
                    error.title = "test"
                }
                let object = json(error)
                expect(object.count).to(equal(2))
                expect(object["status"]).to(equal(404))
                expect(object["title"]).to(equal("test"))
            }
            
            it("should serialize members of the error") {
                let error = JSONAPIError(statusCode: 404) { (error) in
                    error.source = JSONAPIError.Source(pointer: "ptr", parameter: "param")
                    error.meta = ErrorDescription(description: "test")
                }
                
                let object = json(error)
                expect(object.count).to(equal(3))
                
                let source = object["source"].dictionaryValue
                expect(source["pointer"]).to(equal("ptr"))
                expect(source["parameter"]).to(equal("param"))

                let meta = object["meta"].dictionaryValue
                expect(meta["description"]).to(equal("test"))
            }
            
            context("Provides response fields") {
                
                afterEach {
                    Router.disableAll()
                }
                
                it("should affect the status code of the request") { /* occasionally failing test, added diagnostic */
                    let router = Router.register("http://www.test.com")
                    // diagnostic
                    var handlerCalled = false
                    
                    router.get("/users"){ request in
                        handlerCalled = true
                        return JSONAPIError(statusCode: 501) { (error) in
                            error.title = "test"
                        }
                    }
                    
                    var statusCode: Int = -1 // sometimes this test fails, use -1 to distinguish between nil. Looks like a timeout but it's weird that only happens to this test. Maybe the route is not matched sometimes?
                    NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users")!) { (data, response, _) in
                        let response = response as! NSHTTPURLResponse
                        statusCode = response.statusCode
                        // diagnostic
                        expect(statusCode).to(equal(501))
                        }.resume()
                    
                    // diagnostic to check if it's a timeout
                    let startTime = CFAbsoluteTimeGetCurrent()
                    expect(statusCode).toEventually(equal(501))
                    let endTime = CFAbsoluteTimeGetCurrent()
                    expect(endTime - startTime) < 1 // Quick's default timeout, the responde should be done immediately anyway.
                    expect(handlerCalled) == true
                }
                
                it("should affect the header fields of the response") {
                    let router = Router.register("http://www.test.com")
                    
                    router.get("/users"){ request in
                        return JSONAPIError(statusCode: 404, headerFields: ["foo": "bar"]) { (error) in
                            error.title = "test"
                        }
                    }
                    
                    var foo: String?
                    NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users")!) { (data, response, _) in
                        let response = response as! NSHTTPURLResponse
                        let headers = response.allHeaderFields as? [String: String]
                        foo = headers?["foo"]
                        }.resume()
                    
                    expect(foo).toEventually(equal("bar"))
                }
            }
        }
    }
}
