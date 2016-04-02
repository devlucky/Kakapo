//
//  KakapoDBTests.swift
//  KakapoExample
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Quick
import Nimble

@testable import Kakapo

struct UserFactory: KStorable {
    let firstName: String
    let lastName: String
    let age: Int
    let id: Int
    
    init(id: Int) {
        self.init(firstName: randomString(), lastName: randomString(), age: random(), id: id)
    }
    
    init(firstName: String, lastName: String, age: Int, id: Int) {
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.id = id
    }
}

struct CommentFactory: KStorable {
    let text: String
    let likes: Int
    let id: Int
    
    init(id: Int) {
        self.init(text: randomString(), likes: random(), id: id)
    }
    
    init(text: String, likes: Int, id: Int) {
        self.text = text
        self.likes = likes
        self.id = id
    }
}

class KakapoDBTests: QuickSpec {
    
    override func spec() {
        
        describe("#KakapoDB") {
            var db = KakapoDB()
            
            beforeEach({
                db = KakapoDB()
            })

            it("should return the expected object with a given id after inserting 20 objects") {
                db.create(UserFactory.self, number: 20)
                let user = db.find(UserFactory.self, id: 1)
                
                expect(user).toNot(beNil())
                expect(user?.firstName).toNot(beNil())
                expect(user?.id) == 1
            }
            
            it("should return the expected object with a given id after inserting different object types") {
                db.create(UserFactory.self, number: 20)
                db.create(CommentFactory.self, number: 20)
                let user = db.find(UserFactory.self, id: 1)
                let wrongComment = db.find(CommentFactory.self, id: 2)
                let comment = db.find(CommentFactory.self, id: 22)
                
                expect(user).toNot(beNil())
                expect(wrongComment).to(beNil())
                expect(comment).toNot(beNil())
            }
            
            it("shoud return the expected object after inserting it", closure: {
                let _ = try? db.insert(UserFactory(firstName: "Hector", lastName: "Zarco", age:25, id: 90))
                
                let user = db.find(UserFactory.self, id: 90)
                expect(user?.firstName).to(match("Hector"))
                expect(user?.lastName).to(match("Zarco"))
                expect(user?.id) == 90
            })
            
            it("should fail when inserting invalid id", closure: {
                do {
                    try db.insert(UserFactory(firstName: "Joan", lastName: "Romano", age:25, id: 100))
                    try db.insert(UserFactory(firstName: "Joan", lastName: "Romano", age:25, id: 100))
                } catch KakapoDBError.InvalidId {
                    expect(true).to(beTrue())
                } catch {
                    expect(false).to(beTrue())
                }
            })
            
            it("should return the expected filtered element with valid id", closure: {
                let _ = try? db.insert(UserFactory(firstName: "Hector", lastName: "Zarco", age:25, id: 90))
                
                let userArray = db.filter(UserFactory.self, includeElement: { (item) -> Bool in
                    return item.id == 90
                })
                
                expect(userArray.count) == 1
                expect(userArray.first?.firstName).to(match("Hector"))
                expect(userArray.first?.lastName).to(match("Zarco"))
                expect(userArray.first?.id) == 90
            })
            
            it("should return no objects for some inexisting filtering", closure: {
                db.create(UserFactory.self, number: 20)
                let _ = try? db.insert(UserFactory(firstName: "Hector", lastName: "Zarco", age:25, id: 90))
                
                let userArray = db.filter(UserFactory.self, includeElement: { (item) -> Bool in
                    return item.lastName == "Manzella"
                })
                
                expect(userArray.count) == 0
            })

        }
    }
}