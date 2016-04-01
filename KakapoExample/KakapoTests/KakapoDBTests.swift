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

class KakapoDBTests: QuickSpec {
    
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
    
    override func spec() {
        
        describe("#KakapoDB") {
            let db = KakapoDB()

            it("should return the expected object with a given id after inserting 20 objects") {
                db.create(UserFactory.self, number: 20)
                let users = db.find(UserFactory.self, id: 1)
                
                expect(users.count) == 1
                expect(users.first?.firstName).toNot(beNil())
                expect(users.first?.id) == 1
            }
            
            it("shoud return the expected object after inserting it", closure: {
                let _ = try? db.insert(UserFactory(firstName: "Hector", lastName: "Zarco", age:25, id: 90))
                
                let user = db.find(UserFactory.self, id: 90).first!
                expect(user.firstName).to(match("Hector"))
                expect(user.lastName).to(match("Zarco"))
                expect(user.id) == 90
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

        }
    }
}