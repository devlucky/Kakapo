//
//  StoreTests.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Quick
import Nimble
@testable import Kakapo

func random() -> Int {
    return Int(arc4random() % 100)
}

struct User: Storable, Serializable {
    let id: String
    let firstName: String
    let lastName: String
    let age: Int
    
    init(id: String, store: Store) {
        self.init(firstName: "tmp", lastName: "tmp", age: random(), id: id)
    }
    
    init(firstName: String, lastName: String, age: Int, id: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.id = id
    }
}

struct Comment: Storable {
    let id: String
    let text: String
    let likes: Int
    
    init(id: String, store: Store) {
        self.init(text: "tmp", likes: random(), id: id)
    }
    
    init(text: String, likes: Int, id: String) {
        self.text = text
        self.likes = likes % 200
        self.id = id
    }
}

class StoreTests: QuickSpec {
    
    override func spec() {
        
        var sut = Store()
        
        beforeEach {
            sut = Store()
        }
        
        describe("Creation and Insertion") {
            it("should create a large number of elements") {
                DispatchQueue.concurrentPerform(iterations: 1000) { (_) in
                    sut.create(User.self)
                }
                
                DispatchQueue.concurrentPerform(iterations: 5000) { (_) in
                    sut.create(Comment.self)
                }
                
                let userObjects = sut.findAll(User.self)
                let user = sut.find(User.self, id: "1")
                
                let commentObjects = sut.findAll(Comment.self)
                let aComment = sut.find(Comment.self, id: "1000")
                let anotherComment = sut.find(Comment.self, id: "1002")
                
                expect(user).toNot(beNil())
                expect(user?.firstName).toNot(beNil())
                expect(user?.id) == "1"
                expect(userObjects.count) == 1000
                
                expect(aComment).toNot(beNil())
                expect(aComment?.text).toNot(beNil())
                expect(aComment?.id) == "1000"
                
                expect(anotherComment).toNot(beNil())
                expect(anotherComment?.text).toNot(beNil())
                expect(anotherComment?.id) == "1002"
                
                expect(commentObjects.count) == 5000
            }
            
            it("should create a large number of elements respecting the previous ones") {
                DispatchQueue.concurrentPerform(iterations: 1000) { (_) in
                    sut.create(User.self)
                }
                
                let createdObjects = sut.create(User.self, number: 20000)
                let totalObjects = sut.findAll(User.self)
                
                expect(createdObjects.count) == 20000
                expect(totalObjects.count) == 21000
            }
            
            it("should insert a large number of elements") {
                DispatchQueue.concurrentPerform(iterations: 1000) { (_) in
                    sut.insert { (id) -> (User) in
                        return User(firstName: "Name " + id, lastName: "Last Name " + id, age: 10, id: id)
                    }
                }

                let userObjects = sut.findAll(User.self)
                let user = sut.find(User.self, id: "1")
                
                expect(user).toNot(beNil())
                expect(user?.firstName).to(contain("Name 1"))
                expect(user?.lastName).to(contain("Last Name 1"))
                expect(user?.id).to(equal("1"))
                expect(user?.age).to(equal(10))
                expect(userObjects.count) == 1000
            }
        }
        
        describe("Finding and Filtering") {
            it("should return the expected object with a given id after inserting multiple objects") {
                sut.create(User.self, number: 3)
                let user = sut.find(User.self, id: "1")
                
                expect(user).toNot(beNil())
                expect(user?.firstName).toNot(beNil())
                expect(user?.id) == "1"
            }
            
            it("should return the expected object with a given id after inserting different object types") {
                sut.create(User.self, number: 3)
                sut.create(Comment.self, number: 2)
                let user = sut.find(User.self, id: "1")
                let wrongComment = sut.find(Comment.self, id: "2")
                let comment = sut.find(Comment.self, id: "3")
                
                expect(user).toNot(beNil())
                expect(wrongComment).to(beNil())
                expect(comment).toNot(beNil())
            }
            
            it("shoud return the expected object after inserting it") {
                sut.insert { (id) -> User in
                    return User(firstName: "Hector", lastName: "Zarco", age: 25, id: id)
                }
                
                let user = sut.find(User.self, id: "0")
                expect(user?.firstName).to(match("Hector"))
                expect(user?.lastName).to(match("Zarco"))
                expect(user?.id) == "0"
            }
            
            #if arch(x86_64) && _runtime(_ObjC)
            it("should fail a precondition when inserting invalid id") {
                sut.insert { (id) -> User in
                    return User(firstName: "Joan", lastName: "Romano", age: 25, id: id)
                }

                let preconditionTrigger: () -> Void = {
                    sut.insert { (id) -> User in
                        return User(firstName: "Joan", lastName: "Romano", age: 25, id: String(Int(id)! - 1))
                    }
                }
                
                expect(preconditionTrigger()).to(throwAssertion())
            }
            #endif

            it("should return the expected filtered element with valid id") {
                sut.insert { (id) -> User in
                    User(firstName: "Hector", lastName: "Zarco", age: 25, id: id)
                }
                
                let userArray = sut.filter(User.self) { (item) -> Bool in
                    return item.id == "0"
                }
                
                expect(userArray.count) == 1
                expect(userArray.first?.firstName).to(match("Hector"))
                expect(userArray.first?.lastName).to(match("Zarco"))
                expect(userArray.first?.id) == "0"
            }

            it("should return no objects for some inexisting filtering") {
                sut.create(User.self, number: 2)
                sut.insert { (id) -> User in
                    return User(firstName: "Hector", lastName: "Zarco", age: 25, id: id)
                }
                
                let userArray = sut.filter(User.self, isIncluded: { (item) -> Bool in
                    return item.lastName == "Manzella"
                })
                
                expect(userArray.count) == 0
            }
        }
        
        describe("Update") {
            it("should update a previously inserted object") {
                sut.create(User.self, number: 3)
                let elementToUpdate = User(firstName: "Joan", lastName: "Romano", age: 28, id: "2")
                try! sut.update(elementToUpdate)
                let updatedUserInStore = sut.find(User.self, id: "2")
                
                expect(updatedUserInStore?.firstName).to(equal("Joan"))
                expect(updatedUserInStore?.lastName).to(equal("Romano"))
                expect(updatedUserInStore?.age).to(equal(28))
            }
            
            it("should not update an object that was never inserted") {
                sut.create(User.self, number: 2)
                let elementToUpdate = User(firstName: "Joan", lastName: "Romano", age: 28, id: "45")
                expect { try sut.update(elementToUpdate) }.to(throwError(errorType: StoreError.self))
                let updatedUserInStore = sut.find(User.self, id: "45")
                expect(updatedUserInStore).to(beNil())
            }
            
            it("should not update different kind of objects from different stores with same id") {
                let anotherStore = Store()
                sut.create(User.self, number: 2)
                anotherStore.create(Comment.self, number: 2)
                expect { try sut.update(anotherStore.find(Comment.self, id: "0")!) }.to(throwError(errorType: StoreError.self))
                let updatedCommentInStore = sut.find(Comment.self, id: "0")
                expect(updatedCommentInStore).to(beNil())
            }
            
            it("should update same kind of objects from different stores with same id") {
                let anotherStore = Store()
                var theId: String!
                let factory = sut.create(Comment.self).first!
                let likes = factory.likes
                
                anotherStore.insert { (id) -> Comment in
                    theId = id
                    return Comment(text: "a comment", likes: likes + 1, id: id)
                }
                
                try! sut.update(anotherStore.find(Comment.self, id: theId)!)
                let updatedComment = sut.find(Comment.self, id: theId)
                
                expect(updatedComment?.text).to(equal("a comment"))
                expect(updatedComment?.likes).to(equal(likes + 1))
            }
        }
        
        describe("Deletion") {
            it("should delete a previously inserted object") {
                sut.create(User.self, number: 5)
                let elementToDelete = sut.find(User.self, id: "2")!
                try! sut.delete(elementToDelete)
                let usersArray = sut.findAll(User.self)
                
                expect(usersArray.count).to(equal(4))
            }
            
            it("should delete a previously inserted object with same data representation") {
                var theId: String!
                sut.insert { (id) -> User in
                    theId = id
                    return User(firstName: "Joan", lastName: "Romano", age: 28, id: id)
                }
                
                let elementToDelete = User(firstName: "Joan", lastName: "Romano", age: 28, id: theId)
                try! sut.delete(elementToDelete)
                let usersArray = sut.findAll(User.self)
                
                expect(usersArray.count).to(equal(0))
            }
            
            it("should not delete an object with same id but different type") {
                let user = sut.create(User.self).first!
                let elementToDelete = Comment(text: "", likes: 0, id: user.id)
                expect { try sut.delete(elementToDelete) }.to(throwError(errorType: StoreError.self))
                expect(sut.findAll(User.self).count).to(equal(1))
            }
            
            it("should delete an object with same id and same type but different properties") {
                let comment = sut.create(Comment.self).first!
                let elementToDelete = Comment(text: "", likes: comment.likes + 1, id: comment.id)
                expect { try sut.delete(elementToDelete) }.toNot(throwError(errorType: StoreError.self))
                expect(sut.findAll(User.self).count).to(equal(0))
            }
            
            it("should not delete a non previously inserted object") {
                sut.create(User.self)
                let elementToDelete = User(id: "44", store: sut)
                expect { try sut.delete(elementToDelete) }.to(throwError(errorType: StoreError.self))
                expect(sut.findAll(User.self).count).to(equal(1))
            }
            
            it("should not delete objects from different stores with same id") {
                let anotherStore = Store()
                sut.create(User.self, number: 2)
                anotherStore.create(Comment.self, number: 2)
                expect { try sut.delete(anotherStore.find(Comment.self, id: "1")!) }.to(throwError(errorType: StoreError.self))
                expect(sut.findAll(User.self).count).to(equal(2))
            }
            
            it("should delete objects from different stores with same id and data representation") {
                let anotherStore = Store()
                var theId: String!
                sut.insert { (id) -> User in
                    theId = id
                    return User(firstName: "Joan", lastName: "Romano", age: 28, id: id)
                }
                
                sut.create(User.self, number: 44)
                
                anotherStore.insert { (id) -> User in
                    return User(firstName: "Joan", lastName: "Romano", age: 28, id: id)
                }
                
                let elementToDelete = anotherStore.find(User.self, id: theId)!
                try! sut.delete(elementToDelete)
                let usersArray = sut.findAll(User.self)
                
                expect(usersArray.count).to(equal(44))
            }
            
            it("should have no items after deleting all") {
                let sut = Store()
                sut.create(User.self, number: 2000)
                for entity in sut.findAll(User.self) {
                    try! sut.delete(entity)
                }
                
                expect(sut.findAll(User.self).count).to(equal(0))
            }
            
            it("should be able to concurrently delete objects") {
                let users = sut.create(User.self, number: 100)
                DispatchQueue.concurrentPerform(iterations: 100) { (index) in
                    try! sut.delete(users[index])
                }
                expect(sut.findAll(User.self).count).to(equal(0))
            }
            
            it("should be able to concurrently update and delete objects") {
                let users = sut.create(User.self, number: 100)
                
                DispatchQueue.concurrentPerform(iterations: 100) { (index) in
                    try! sut.update(users[index])
                    try! sut.delete(users[index])
                }
                expect(sut.findAll(User.self)).to(beEmpty())
            }
        }
        
        describe("store Operations Deadlock 💀💀💀💀💀💀💀💀") {
            let queue = DispatchQueue(label: "com.store.testDeadlock")
            
            beforeEach {
                sut.insert { id -> User in
                   return User(id: id, store: sut)
                }
            }
            
            it("should not deadlock when writing into store during a writing operation") {
                let user = sut.insert { (id) -> User in
                    sut.insert { (id) -> User in
                        return User(id: id, store: sut)
                    }
                    
                    return User(id: id, store: sut)
                }
                
                expect(user).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when synchronously writing from another queue into the store during a writing operation") {
                let user = sut.insert { (id) -> User in
                    _ = queue.sync {
                        sut.insert { (id) -> User in
                            return User(id: id, store: sut)
                        }
                    }
                    return User(id: id, store: sut)
                }
                expect(user).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when writing into the store during a reading operation") {
                let result = sut.filter(User.self, isIncluded: { (_) -> Bool in
                    sut.create(User.self)
                    return true
                })
                
                expect(result).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when synchronously writing from another queue into the store during a reading operation") {
                let result = sut.filter(User.self, isIncluded: { (_) -> Bool in
                    _ = queue.sync {
                        sut.create(User.self)
                    }
                    return true
                })
                
                expect(result).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when reading the store during a read operation") {
                let result = sut.filter(User.self, isIncluded: { (_) -> Bool in
                    _ = sut.findAll(User.self)
                    return true
                })
                
                expect(result).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when synchronously reading the store from another queue during a reading operation") {
                let result = sut.filter(User.self, isIncluded: { (_) -> Bool in
                    _ = queue.sync {
                        sut.findAll(User.self)
                    }
                    return true
                })
                
                expect(result).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when reading the store during a write operation") {
                let user = sut.insert { (id) -> User in
                    _ = sut.findAll(User.self)
                    return User(id: id, store: sut)
                }
                expect(user).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when synchronously reading the store from another queue during a write operation") {
                let user = sut.insert { (id) -> User in
                    _ = queue.sync {
                        sut.findAll(User.self)
                    }
                    return User(id: id, store: sut)
                }
                expect(user).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when synchronously updating the store from another queue during a write operation") {
                let user = sut.insert { (id) -> User in
                    queue.sync {
                        try! sut.update(User(id: "0", store: sut))
                    }
                    return User(id: id, store: sut)
                }
                expect(user).toEventuallyNot(beNil())
            }
            
            it("should not deadlock when synchronously deleting the store from another queue during a write operation") {
                let user = sut.insert { (id) -> User in
                    queue.sync {
                        try! sut.delete(sut.find(User.self, id: "0")!)
                    }
                    return User(id: id, store: sut)
                }
                
                let users = sut.findAll(User.self)
                
                expect(user).toEventuallyNot(beNil())
                expect(users.count).toEventually(equal(1))
            }
            
            it("should not deadlock when deleting into store during a reading operation") {
                let result = sut.filter(User.self, isIncluded: { (_) -> Bool in
                    try! sut.delete(sut.find(User.self, id: "0")!)
                    return true
                })
                
                let users = sut.findAll(User.self)
                
                expect(result).toEventuallyNot(beNil())
                expect(users.count).toEventually(equal(0))
            }
            
            it("should not deadlock when updating into store during a reading operation") {
                let result = sut.filter(User.self, isIncluded: { (_) -> Bool in
                    try! sut.update(User(firstName: "Alex", lastName: "Manzella", age: 30, id: "0"))
                    return true
                })
                
                let user = sut.findAll(User.self).first!
                
                expect(result).toEventuallyNot(beNil())
                expect(user.firstName).toEventually(equal("Alex"))
                expect(user.lastName).toEventually(equal("Manzella"))
                expect(user.age).toEventually(equal(30))
            }
        }
    }
}

class StorePerformaceTests: XCTestCase {
    
    func testMultipleSingleCreationPerformance() {
        let sut = Store()
        measure {
            DispatchQueue.concurrentPerform(iterations: 1000) { _ in
                sut.create(User.self)
            }
        }
    }
    
    func testMultpleInsertionsPerformance() {
        let sut = Store()
        measure {
            DispatchQueue.concurrentPerform(iterations: 1000) { _ in
                sut.insert { (id) -> User in
                    return User(id: id, store: sut)
                }
            }
        }
    }
    
    func testMultipleDeletionsPerformance() {
        let sut = Store()
        sut.create(User.self, number: 2000)
        measure {
            for entity in sut.findAll(User.self) {
                try! sut.delete(entity)
            }
        }
    }
}
