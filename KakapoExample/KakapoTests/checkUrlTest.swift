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
                expect(checkUrl("/users/:id", requestUrl: "/comments/1")).to(beNil())
                expect(checkUrl("/users/:id", requestUrl: "/users/")).to(beNil())
                expect(checkUrl("/users/:id/comments", requestUrl: "/users/1")).to(beNil())
                expect(checkUrl("/users/:user_id/comments/:comment_id", requestUrl: "/users/1/comments")).to(beNil())
            }
            it("should return the request params if the requested url matches the declared one") {
                expect(checkUrl("/users", requestUrl: "/users")!.params) == [:]
                expect(checkUrl("/users/:id", requestUrl: "/users/1")!.params) == ["id" : "1"]
                expect(checkUrl("/users/:id/comments", requestUrl: "/users/1/comments")!.params) == ["id" : "1"]
                expect(checkUrl("/users/:user_id/comments/:comment_id", requestUrl: "/users/1/comments/2")!.params) == ["user_id" : "1", "comment_id": "2"]
            }
            it("should match the url when query params are present") {
                expect(checkUrl("/users", requestUrl: "/users?page=2")!.params) == [:]
                expect(checkUrl("/users/:id", requestUrl: "/users/1?page=2")!.params) == ["id": "1"]
                expect(checkUrl("/users/:id", requestUrl: "/users/1?page=2")!.queryParams) == ["page": "2"]
                expect(checkUrl("/users/:id/comments/:comment_id", requestUrl: "/users/1/comments/2?page=2&author=hector")!.params) == ["id": "1", "comment_id": "2"]
                expect(checkUrl("/users/:id/comments/:comment_id", requestUrl: "/users/1/comments/2?page=2&author=hector")!.queryParams) == ["page": "2", "author": "hector"]
            }
        }
    }
}
