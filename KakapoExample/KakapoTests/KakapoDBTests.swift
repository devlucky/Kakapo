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

struct UserFactory: Storable, Serializable {
    let firstName: String
    let lastName: String
    let age: Int
    let id: Int
    
    init(id: Int, db: KakapoDB) {
        self.init(firstName: randomString(), lastName: randomString(), age: random(), id: id)
    }
    
    init(firstName: String, lastName: String, age: Int, id: Int) {
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.id = id
    }
}

struct CommentFactory: Storable {
    let text: String
    let likes: Int
    let id: Int
    
    init(id: Int, db: KakapoDB) {
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
            var sut = KakapoDB()
            
            beforeEach({
                sut = KakapoDB()
            })
            
            it("should create a large number of elements") {
                let queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT)
                dispatch_apply(1000, queue, { i in
                    sut.create(UserFactory.self)
                })
                
                dispatch_apply(5000, queue, { i in
                    sut.create(CommentFactory.self)
                })
                
                let userObjects = sut.findAll(UserFactory.self)
                let user = sut.find(UserFactory.self, id: 1)
                
                let commentObjects = sut.findAll(CommentFactory.self)
                let aComment = sut.find(CommentFactory.self, id: 1000)
                let anotherComment = sut.find(CommentFactory.self, id: 1002)
                
                expect(user).toNot(beNil())
                expect(user?.firstName).toNot(beNil())
                expect(user?.id) == 1
                expect(userObjects.count) == 1000
                
                expect(aComment).toNot(beNil())
                expect(aComment?.text).toNot(beNil())
                expect(aComment?.id) == 1000
                
                expect(anotherComment).toNot(beNil())
                expect(anotherComment?.text).toNot(beNil())
                expect(anotherComment?.id) == 1002
                
                expect(commentObjects.count) == 5000
            }
            
            it("should create a large number of elements respecting the previous ones") {
                let queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT)
                dispatch_apply(1000, queue, { i in
                    sut.create(UserFactory.self)
                })
                
                let createdObjects = sut.create(UserFactory.self, number: 20000)
                let totalObjects = sut.findAll(UserFactory.self)
                
                expect(createdObjects.count) == 20000
                expect(totalObjects.count) == 21000
            }
            
            it("should insert a large number of elements") {
                dispatch_apply(1000, dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT), { _ in
                    sut.insert { (id) -> UserFactory in
                        return UserFactory(firstName: "Name " + String(id), lastName: "Last Name " + String(id), age: id, id: id)
                    }
                })
                
                let userObjects = sut.findAll(UserFactory.self)
                let user = sut.find(UserFactory.self, id: 1)
                
                expect(user).toNot(beNil())
                expect(user?.firstName).to(contain("Name 1"))
                expect(user?.lastName).to(contain("Last Name 1"))
                expect(user?.id).toNot(beNil())
                expect(user?.age).toNot(beNil())
                expect(userObjects.count) == 1000
            }

            it("should return the expected object with a given id after inserting 20 objects") {
                sut.create(UserFactory.self, number: 20)
                let user = sut.find(UserFactory.self, id: 1)
                
                expect(user).toNot(beNil())
                expect(user?.firstName).toNot(beNil())
                expect(user?.id) == 1
            }
            
            it("should return the expected object with a given id after inserting different object types") {
                sut.create(UserFactory.self, number: 20)
                sut.create(CommentFactory.self, number: 20)
                let user = sut.find(UserFactory.self, id: 1)
                let wrongComment = sut.find(CommentFactory.self, id: 2)
                let comment = sut.find(CommentFactory.self, id: 22)
                
                expect(user).toNot(beNil())
                expect(wrongComment).to(beNil())
                expect(comment).toNot(beNil())
            }
            
            it("shoud return the expected object after inserting it") {
                sut.insert { (id) -> UserFactory in
                    return UserFactory(firstName: "Hector", lastName: "Zarco", age:25, id: id)
                }
                
                let user = sut.find(UserFactory.self, id: 0)
                expect(user?.firstName).to(match("Hector"))
                expect(user?.lastName).to(match("Zarco"))
                expect(user?.id) == 0
            }
            
            it("should fail when inserting invalid id") {
                sut.insert { (id) -> UserFactory in
                    return UserFactory(firstName: "Joan", lastName: "Romano", age:25, id: id)
                }

//                TODO: TEST THIS FATAL ERROR
//                expect{ sut.insert({ (id) -> UserFactory in
//                    return UserFactory(firstName: "Joan", lastName: "Romano", age:25, id: id-1)
//                })}.to(throwError())
            }

            it("should return the expected filtered element with valid id") {
                sut.insert { (id) -> UserFactory in
                    UserFactory(firstName: "Hector", lastName: "Zarco", age:25, id: id)
                }
                
                let userArray = sut.filter(UserFactory.self, includeElement: { (item) -> Bool in
                    return item.id == 0
                })
                
                expect(userArray.count) == 1
                expect(userArray.first?.firstName).to(match("Hector"))
                expect(userArray.first?.lastName).to(match("Zarco"))
                expect(userArray.first?.id) == 0
            }

            it("should return no objects for some inexisting filtering") {
                sut.create(UserFactory.self, number: 20)
                sut.insert { (id) -> UserFactory in
                    return UserFactory(firstName: "Hector", lastName: "Zarco", age:25, id: id)
                }
                
                let userArray = sut.filter(UserFactory.self, includeElement: { (item) -> Bool in
                    return item.lastName == "Manzella"
                })
                
                expect(userArray.count) == 0
            }
        }
        
        describe("Database Operations Deadlock 💀💀💀💀💀💀💀💀") {
            let sut = KakapoDB()
            let queue = dispatch_queue_create("com.kakapodb.testDeadlock", DISPATCH_QUEUE_SERIAL)
            
            it("should not deadlock when writing into database during a writing operation") {
                let user = sut.insert { (id) -> UserFactory in
                    sut.insert { (id) -> UserFactory in
                        return UserFactory(id: id, db: sut)
                    }
                    
                    return UserFactory(id: id, db: sut)
                }
                
                expect(user).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when synchronously writing from another queue into database during a writing operation") {
                let user = sut.insert { (id) -> UserFactory in
                    dispatch_sync(queue) {
                        sut.insert { (id) -> UserFactory in
                            return UserFactory(id: id, db: sut)
                        }
                    }
                    return UserFactory(id: id, db: sut)
                }
                expect(user).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when writing into database during a reading operation") {
                let result = sut.filter(UserFactory.self, includeElement: { (_) -> Bool in
                    sut.create(UserFactory)
                    return true
                })
                
                expect(result).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when synchronously writing from another queue into database during a reading operation") {
                let result = sut.filter(UserFactory.self, includeElement: { (_) -> Bool in
                    dispatch_sync(queue) {
                        sut.create(UserFactory)
                    }
                    return true
                })
                
                expect(result).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when reading the database during a read operation") {
                let result = sut.filter(UserFactory.self, includeElement: { (_) -> Bool in
                    sut.findAll(UserFactory.self)
                    return true
                })
                
                expect(result).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when synchronously reading the database from another queue during a reading operation") {
                let result = sut.filter(UserFactory.self, includeElement: { (_) -> Bool in
                    dispatch_sync(queue) {
                        sut.findAll(UserFactory.self)
                    }
                    return true
                })
                
                expect(result).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when reading the database during a write operation") {
                let user = sut.insert { (id) -> UserFactory in
                    sut.findAll(UserFactory.self)
                    return UserFactory(id: id, db: sut)
                }
                expect(user).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when synchronously reading the database from another queue during a write operation") {
                let user = sut.insert { (id) -> UserFactory in
                    dispatch_sync(queue) {
                        sut.findAll(UserFactory.self)
                    }
                    return UserFactory(id: id, db: sut)
                }
                expect(user).toEventuallyNot(beNil())
            }
        }
    }
}

class KakapoDBPerformaceTests: XCTestCase {
    
    func testMultipleSingleCreationPerformance() {
        let sut = KakapoDB()
        measureBlock {
            dispatch_apply(1000, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { _ in
                sut.create(UserFactory.self)
            }
        }
    }
    
    func testMultpleInsertionsPerformance() {
        let sut = KakapoDB()
        measureBlock {
            dispatch_apply(1000, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { _ in
                sut.insert { (id) -> UserFactory in
                    return UserFactory(id: id, db: sut)
                }
            }
        }
    }
}