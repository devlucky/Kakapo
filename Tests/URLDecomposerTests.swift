//
//  URLDecomposerTests.swift
//  KakapoExample
//
//  Created by Hector Zarco on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Quick
import Nimble

@testable import Kakapo

class URLDecomposerTests: QuickSpec {
    override func spec() {
        describe("not matching") {
            it("it should not match a handler path with a different request path") {
                expect(decomposeURL("/users/:id", requestURLComponents: NSURLComponents(string: "/comments/1")!)).to(beNil())
            }
            
            it("it should not match a handler path with wilcard with a request path with no wildcard") {
                expect(decomposeURL("/users/:id", requestURLComponents: NSURLComponents(string: "/users/")!)).to(beNil())
            }
            
            it("it should not match a handler path and a request path with different wilcard combinations") {
                expect(decomposeURL("/users/:id/comments", requestURLComponents: NSURLComponents(string: "/users/1")!)).to(beNil())
            }
            
            it("it should not match a handler path and a request path with different wilcard combinations 2") {
                expect(decomposeURL("/users/:user_id/comments/:comment_id", requestURLComponents: NSURLComponents(string: "/users/1/comments")!)).to(beNil())
            }
            
            it("it should not match a handler path and a request path with different wilcard combinations 3") {
                expect(decomposeURL("/users/:id/comments", requestURLComponents: NSURLComponents(string: "/users/1/comments/2")!)).to(beNil())
            }
        }
        
        describe("matching components") {
            it("it should match a handler path with no wilcard with the same request path") {
                expect(decomposeURL("/users", requestURLComponents: NSURLComponents(string: "/users")!)!.components) == [:]
            }
            
            it("it should match a handler path and request path with same wilcard") {
                expect(decomposeURL("/users/:id", requestURLComponents: NSURLComponents(string: "/users/1")!)!.components) == ["id" : "1"]
            }
            
            it("it should match a handler path and request path with same wilcard combinations") {
                expect(decomposeURL("/users/:id/comments", requestURLComponents: NSURLComponents(string: "/users/1/comments")!)!.components) == ["id" : "1"]
            }
            
            it("it should match a handler path and request path with same wilcard combinations 2") {
                expect(decomposeURL("/users/:user_id/comments/:comment_id", requestURLComponents: NSURLComponents(string: "/users/1/comments/2")!)!.components) == ["user_id" : "1", "comment_id": "2"]
            }
        }
        
        describe("matching with query parameters") {
            it("it should match a handler path with no wilcard with the same request path with query parameters, providing the proper components") {
                expect(decomposeURL("/users", requestURLComponents: NSURLComponents(string: "/users?page=2/")!)!.components) == [:]
            }
            
            it("it should match a handler path and a request path with same wilcard and with query parameters, providing the proper components") {
                expect(decomposeURL("/users/:id", requestURLComponents: NSURLComponents(string: "/users/1?page=2/")!)!.components) == ["id": "1"]
            }
            
            it("it should match a handler path and a request path with same wilcard and with query parameters, providing the proper query parameters") {
                expect(decomposeURL("/users/:id", requestURLComponents: NSURLComponents(string: "/users/1?page=2")!)!.queryParameters) == [NSURLQueryItem(name: "page", value: "2")]
            }
            
            it ("it should match a handler path and a request path with same wilcard combination and with query parameters, providing the proper components") {
                expect(decomposeURL("/users/:id/comments/:comment_id", requestURLComponents: NSURLComponents(string: "/users/1/comments/2?page=2&author=hector")!)!.components) == ["id": "1", "comment_id": "2"]
            }
            
            it ("it should match a handler path and a request path with same wilcard combination and with query parameters, providing the proper query parameters") {
                expect(decomposeURL("/users/:id/comments/:comment_id", requestURLComponents: NSURLComponents(string: "/users/1/comments/2?page=2&author=hector")!)!.queryParameters) == [NSURLQueryItem(name: "page", value: "2"), NSURLQueryItem(name: "author", value: "hector")]
            }
        }
    }
}
