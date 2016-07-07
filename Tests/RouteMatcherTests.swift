//
//  RouteMatcherTests.swift
//  Kakapo
//
//  Created by Hector Zarco on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Quick
import Nimble

@testable import Kakapo

class RouteMatcherTests: QuickSpec {
    override func spec() {
        
        func decompose(path path: String, requestURL: String) -> URLInfo? {
            return decomposeURL(base: "http://test.com/",
                                path: path,
                                requestURL: NSURL(string: "http://test.com/"+requestURL)!)
        }
        
        describe("Route matching") {
            context("when the path is not representing the requetsURL") {
                
                it("should not match if the base is different") {
                    let result = decomposeURL(base: "http://test.com/",
                                              path: "/users/:id",
                                              requestURL: NSURL(string: "http://foo.com/users/1")!)
                    expect(result).to(beNil())
                }
                
                it("should not match if the path is different") {
                    expect(decompose(path: "/users/:id", requestURL: "/comments/1")).to(beNil())
                }
                
                it("should not match if the wildcard is missing") {
                    expect(decompose(path: "/users/:id", requestURL: "/users/")).to(beNil())
                }
                
                it("should not match if a component is missing") {
                    expect(decompose(path: "/users/:id/comments", requestURL: "/users/1")).to(beNil())
                }
                
                it("should not match if a component doesn't match") {
                    expect(decompose(path: "/users/:user_id/comments/:comment_id", requestURL: "/users/1/whatever/2")).to(beNil())
                }
                
                it("should not match if the request has extra components") {
                    expect(decompose(path: "/users/:id/comments", requestURL: "/users/1/comments/2")).to(beNil())
                }
            }
            
            context("when the path is representing the requestURL") {
                
                it("should match even if the base url is empty") {
                    expect(decomposeURL(base: "", path: "/users", requestURL: NSURL(string: "/users")!)?.components) == [:]
                }
                
                it("should match a path without wilcard and equal components") {
                    expect(decompose(path: "/users", requestURL: "/users")?.components) == [:]
                }
                
                it("should match a path containing a wildcard") {
                    expect(decompose(path: "/users/:id", requestURL: "/users/1")?.components) == ["id" : "1"]
                }
                
                it("should match a path with equal components except for wildcard") {
                    expect(decompose(path: "/users/:id/comments", requestURL: "/users/1/comments")?.components) == ["id" : "1"]
                }
                
                it("should match a path with multiple wildcards") {
                    expect(decompose(path: "/users/:user_id/comments/:comment_id", requestURL: "/users/1/comments/2")?.components) == ["user_id" : "1", "comment_id": "2"]
                }
                
                it("should match a path with only wildcards") {
                    expect(decompose(path: "/:user_id/:comment_id", requestURL: "/1/2/")?.components) == ["user_id" : "1", "comment_id": "2"]
                }
                
                context("when the request contains query parameters") {
                    
                    it("should match a path") {
                        expect(decompose(path: "/users/:id/comments", requestURL: "/users/1/comments?page=2")?.components) == ["id" : "1"]
                    }
                    
                    it("should match a path when there are not actual parameters") {
                        let info = decompose(path: "/users/:id", requestURL: "/users/1?")
                        expect(info?.components) == ["id": "1"]
                        expect(info?.queryParameters) == []
                    }
                    
                    it("should match a path when there is a trailing question mark") {
                        let info = decompose(path: "/users", requestURL: "/users?")
                        expect(info?.components) == [:]
                        expect(info?.queryParameters) == []
                    }
                    
                    it("should retreive the query parameter") {
                        expect(decompose(path: "/users/:id", requestURL: "/users/1?page=2")?.queryParameters) == [NSURLQueryItem(name: "page", value: "2")]
                    }
                    
                    it("should retreive multiple query parameters") {
                        expect(decompose(path: "/users/:id", requestURL: "/users/1?page=2&size=50")?.queryParameters) == [NSURLQueryItem(name: "page", value: "2"), NSURLQueryItem(name: "size", value: "50")]
                    }
                }
            }
            
            context("trailing and leading slashes") {
                // TODO:
            }
        }
    }
}
