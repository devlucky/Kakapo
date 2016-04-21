//
//  checkUrlTest.swift
//  KakapoExample
//
//  Created by Hector Zarco on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Quick
import Nimble

@testable import Kakapo

class checkUrlTest: QuickSpec {
    override func spec() {
        describe("#checkUrl") {
            it("should return nil if the requested url doesn't match the declared one") {
                expect(parseUrl("/users/:id", requestURL: "/comments/1")).to(beNil())
                expect(parseUrl("/users/:id", requestURL: "/users/")).to(beNil())
                expect(parseUrl("/users/:id/comments", requestURL: "/users/1")).to(beNil())
                expect(parseUrl("/users/:user_id/comments/:comment_id", requestURL: "/users/1/comments")).to(beNil())
                expect(parseUrl("/users/:id/comments", requestURL: "/users/1/comments/2")).to(beNil())
            }
            it("should return the request components if the requested url matches the declared one") {
                expect(parseUrl("/users", requestURL: "/users")!.components) == [:]
                expect(parseUrl("/users/:id", requestURL: "/users/1")!.components) == ["id" : "1"]
                expect(parseUrl("/users/:id/comments", requestURL: "/users/1/comments")!.components) == ["id" : "1"]
                expect(parseUrl("/users/:user_id/comments/:comment_id", requestURL: "/users/1/comments/2")!.components) == ["user_id" : "1", "comment_id": "2"]
            }
            it("should match the url when query parameters are present") {
                expect(parseUrl("/users", requestURL: "/users?page=2")!.components) == [:]
                expect(parseUrl("/users/:id", requestURL: "/users/1?page=2")!.components) == ["id": "1"]
                expect(parseUrl("/users/:id", requestURL: "/users/1?page=2")!.queryParameters) == ["page": "2"]
                expect(parseUrl("/users/:id/comments/:comment_id", requestURL: "/users/1/comments/2?page=2&author=hector")!.components) == ["id": "1", "comment_id": "2"]
                expect(parseUrl("/users/:id/comments/:comment_id", requestURL: "/users/1/comments/2?page=2&author=hector")!.queryParameters) == ["page": "2", "author": "hector"]
            }
        }
    }
}
