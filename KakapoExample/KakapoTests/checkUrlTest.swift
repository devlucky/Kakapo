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
                expect(checkUrl("/users/:id", requestUrl: "/users/1")) == ["id" : "1"]
                expect(checkUrl("/users/:id/comments", requestUrl: "/users/1/comments")) == ["id" : "1"]
                expect(checkUrl("/users/:user_id/comments/:comment_id", requestUrl: "/users/1/comments/2")) == ["user_id" : "1", "comment_id": "2"]
            }
        }
    }
}
