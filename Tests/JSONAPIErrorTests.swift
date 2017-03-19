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

        func json(_ object: Serializable) -> JSON {
            return JSON(object.serialized()!)
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
                
                beforeEach {
                    RouterTestServer.register()
                }
                
                afterEach {
                    RouterTestServer.disable()
                    Router.disableAll()
                }

                it("should affect the status code of the request") {
                    let router = Router.register("http://www.test123.com")

                    router.get("/users") { _ in
                        return JSONAPIError(statusCode: 403) { (error) in
                            error.title = "test"
                        }
                    }
                    
                    var statusCode: Int = -1
                    let url = URL(string: "http://www.test123.com/users")!
                    URLSession.shared.dataTask(with: url) { (_, response, _) in
                        let response = response as! HTTPURLResponse
                        statusCode = response.statusCode
                        }.resume()

                    expect(statusCode).toEventually(equal(403), timeout: 2)
                }
            }
        }
    }
}
