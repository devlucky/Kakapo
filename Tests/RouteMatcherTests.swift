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
        
        func match(_ path: String, requestURL: String) -> URLInfo? {
            return matchRoute("http://test.com/",
                                path: path,
                                requestURL: URL(string: "http://test.com/"+requestURL)!)
        }
        
        describe("Route matching") {
            context("when the path is not representing the requetsURL") {
                
                it("should not match if the base is different") {
                    let result = matchRoute("http://test.com/",
                                              path: "/users/:id",
                                              requestURL: URL(string: "http://foo.com/users/1")!)
                    expect(result).to(beNil())
                }
                
                it("should not match if the path is different") {
                    expect(match("/users/:id", requestURL: "/comments/1")).to(beNil())
                }
                
                it("should not match if the wildcard is missing") {
                    expect(match("/users/:id", requestURL: "/users/")).to(beNil())
                }
                
                it("should not match if a component is missing") {
                    expect(match("/users/:id/comments", requestURL: "/users/1")).to(beNil())
                }
                
                it("should not match if a component doesn't match") {
                    expect(match("/users/:user_id/comments/:comment_id", requestURL: "/users/1/whatever/2")).to(beNil())
                }
                
                it("should not match if the request has extra components") {
                    expect(match("/users/:id/comments", requestURL: "/users/1/comments/2")).to(beNil())
                }
            }
            
            context("when the path is representing the requestURL") {
                
                it("should match even if the base url is empty") {
                    expect(matchRoute("", path: "/users", requestURL: URL(string: "/users")!)?.components) == [:]
                }
                
                it("should match a path without wilcard and equal components") {
                    expect(match("/users", requestURL: "/users")?.components) == [:]
                }
                
                it("should match a path containing a wildcard") {
                    expect(match("/users/:id", requestURL: "/users/1")?.components) == ["id" : "1"]
                }
                
                it("should match a path with equal components except for wildcard") {
                    expect(match("/users/:id/comments", requestURL: "/users/1/comments")?.components) == ["id" : "1"]
                }
                
                it("should match a path with multiple wildcards") {
                    expect(match("/users/:user_id/comments/:comment_id", requestURL: "/users/1/comments/2")?.components) == ["user_id" : "1", "comment_id": "2"]
                }
                
                it("should match a path with only wildcards") {
                    expect(match("/:user_id/:comment_id", requestURL: "/1/2/")?.components) == ["user_id" : "1", "comment_id": "2"]
                }
                
                context("when the request contains query parameters") {
                    
                    it("should match a path") {
                        expect(match("/users/:id/comments", requestURL: "/users/1/comments?page=2")?.components) == ["id" : "1"]
                    }
                    
                    it("should match a path when there are not actual parameters") {
                        let info = match("/users/:id", requestURL: "/users/1?")
                        expect(info?.components) == ["id": "1"]
                        expect(info?.queryParameters) == []
                    }
                    
                    it("should match a path when there is a trailing question mark") {
                        let info = match("/users", requestURL: "/users?")
                        expect(info?.components) == [:]
                        expect(info?.queryParameters) == []
                    }
                    
                    it("should retreive the query parameter") {
                        expect(match("/users/:id", requestURL: "/users/1?page=2")?.queryParameters) == [URLQueryItem(name: "page", value: "2")]
                    }
                    
                    it("should retreive multiple query parameters") {
                        let queryParameters = [URLQueryItem(name: "page", value: "2"), URLQueryItem(name: "size", value: "50")]
                        expect(match("/users/:id", requestURL: "/users/1?page=2&size=50")?.queryParameters) == queryParameters
                    }
                }
            }
            
            context("base url") {
                it("shoud match if the base url contains the scheme") {
                    let result = matchRoute("http://test.com/",
                                            path: "/users/:id",
                                            requestURL: URL(string: "http://test.com/users/1")!)
                    expect(result?.components) == ["id" : "1"]

                }
                
                it("shoud not match if the base url contains a different the scheme") {
                    let result = matchRoute("http://test.com/",
                                            path: "/users/:id",
                                            requestURL: URL(string: "https://test.com/users/1")!)
                    expect(result).to(beNil())
                }
                
                it("shoud match any scheme if the base url doesn't contain the scheme") {
                    let result = matchRoute("test.com/",
                                            path: "/users/:id",
                                            requestURL: URL(string: "ssh://test.com/users/1")!)
                    expect(result?.components) == ["id" : "1"]
                }
                
                it("shoud match if the base url contains components") {
                    let result = matchRoute("http://test.com/api/v3/",
                                            path: "/users/:id",
                                            requestURL: URL(string: "http://test.com/api/v3/users/1")!)
                    expect(result?.components) == ["id" : "1"]
                }
                
                it("shoud not match if the base url contains wildcard") {
                    let result = matchRoute("http://test.com/api/:api_version/",
                                            path: "/users/:id",
                                            requestURL: URL(string: "http://test.com/api/v3/users/1")!)
                    expect(result).to(beNil())
                }
                
                it("should match any subdomain when the base url doesn't contain a scheme (wildcard baseURL)") {
                    let result = matchRoute("test.com/",
                                            path: "/users/:id",
                                            requestURL: URL(string: "http://api.test.com/users/1")!)
                    expect(result?.components) == ["id" : "1"]
                }
            }

            context("trailing and leading slashes") {
                
                context("base url and path") {
                    it("should match when base url contains a trailing slash and the path doesn't contain a leading slash") {
                        let result = matchRoute("http://test.com/api/v3/",
                                                path: "users/:id",
                                                requestURL: URL(string: "http://test.com/api/v3/users/1")!)
                        expect(result?.components) == ["id" : "1"]
                    }
                    
                    it("should match when base url contains a trailing slash and the path contains a leading slash") {
                        let result = matchRoute("http://test.com/api/v3/",
                                                path: "/users/:id",
                                                requestURL: URL(string: "http://test.com/api/v3/users/1")!)
                        expect(result?.components) == ["id" : "1"]
                    }
                    
                    it("should match when base url doesn't contain a trailing slash and the path contains a leading slash") {
                        let result = matchRoute("http://test.com/api/v3",
                                                path: "/users/:id",
                                                requestURL: URL(string: "http://test.com/api/v3/users/1")!)
                        expect(result?.components) == ["id" : "1"]
                    }
                    
                    it("should match when base url doesn't contain a trailing slash and the path doesn't contain a leading slash") {
                        let result = matchRoute("http://test.com/api/v3",
                                                path: "users/:id",
                                                requestURL: URL(string: "http://test.com/api/v3/users/1")!)
                        expect(result?.components) == ["id" : "1"]
                    }
                }
                
                context("path and requestURL") {
                    it("should match when path contains a trailing slash and the requestURL doesn't contain a leading slash") {
                        let result = matchRoute("http://test.com/api/v3/",
                                                path: "/users/:id/",
                                                requestURL: URL(string: "http://test.com/api/v3/users/1")!)
                        expect(result?.components) == ["id" : "1"]
                    }
                    
                    it("should match when path contains a trailing slash and the requestURL contains a leading slash") {
                        let result = matchRoute("http://test.com/api/v3/",
                                                path: "/users/:id/",
                                                requestURL: URL(string: "http://test.com/api/v3/users/1/")!)
                        expect(result?.components) == ["id" : "1"]
                    }
                    
                    it("should match when path doesn't contain a trailing slash and the requestURL contains a leading slash") {
                        let result = matchRoute("http://test.com/api/v3/",
                                                path: "/users/:id",
                                                requestURL: URL(string: "http://test.com/api/v3/users/1/")!)
                        expect(result?.components) == ["id" : "1"]
                    }
                    
                    it("should match when path doesn't contain a trailing slash and the requestURL doesn't contain a leading slash") {
                        let result = matchRoute("http://test.com/api/v3/",
                                                path: "/users/:id",
                                                requestURL: URL(string: "http://test.com/api/v3/users/1")!)
                        expect(result?.components) == ["id" : "1"]
                    }
                }
            }
        }
    }
}
