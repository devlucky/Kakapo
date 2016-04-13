//
//  SerializerTests.swift
//  KakapoExample
//
//  Created by Alex Manzella on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Kakapo

class IgnorableNilPropertySpec: QuickSpec {
    override func spec() {
        describe("Nil ignorable property") {
            it("is nil") {
                let ignorableProperty = IgnorableNilProperty<Int>(nil)
                expect(ignorableProperty.shouldSerialize).to(beFalse())
            }
            
            it("is not nil") {
                let ignorableProperty = IgnorableNilProperty(1)
                expect(ignorableProperty.shouldSerialize).to(beTrue())
            }
        }
    }
}

struct MaybeEmpty<T>: Serializable {
    let value: T
    
    init(_ obj: T) {
        value = obj
    }
}

class SerializeSpec: QuickSpec {
    
    struct User: Serializable {
        let name: String
    }
    
    struct Friend: Serializable {
        let friends: [User]
        
        init(friends: [User]) {
            self.friends = friends
        }
    }
    
    override func spec() {
        let user = User(name: "Alex")
        
        describe("Serialization of Serializable entities") {
            it("produce a dictionary where properties are keys and values are values") {
                let serialized = user.serialize() as! [String: Any]
                expect(serialized["name"] as? String).to(equal("Alex"))
            }
            
            it("serialize arrays") {
                let friend = Friend(friends: [user])
                let serialized = friend.serialize() as! [String: Any]
                let friends = serialized["friends"] as? [Any]
                let first = friends?.first as? [String: Any]
                expect(first?.keys.first).to(equal("name"))
                expect(first?.values.first as? String).to(equal("Alex"))
                expect(friends?.count).to(be(1))
            }
        }
        
        describe("Array serialization") {
            
            it("should return an array as an entry point") {
                let serialized = [user].serialize() as! [Any]
                let first = serialized.first as! [String: Any]
                expect(first["name"] as? String).to(equal("Alex"))
            }
            
            func checkObject(object: Any?) {
                let obj = object as? [String: Any]
                expect(obj?.keys.first).to(equal("name"))
                expect(obj?.values.first as? String).to(equal("Alex"))
            }
            
            it("serialize arrays and entities inside it") {
                let friend = Friend(friends: [user, user, user])
                let serialized = friend.serialize() as! [String: Any]
                let friends = serialized["friends"] as! [Any]
                expect(friends.count).to(be(3))
                for friend in friends {
                    checkObject(friend)
                }
            }

            it("recursively serialize arrays") {
                let container = MaybeEmpty([[user]])
                let serialized = container.serialize() as! [String: Any]
                let array = serialized["value"] as? [Any]
                let innerArray = array?.first as? [Any]
                checkObject(innerArray?.first)
            }
        }
        
        describe("Dictionary serialization") {
            
            it("should serialize a dictionary as an entry point") {
                let serialized = ["test": user].serialize() as! [String: Any]
                let user = serialized["test"] as! [String: Any]
                expect(user["name"] as? String).to(equal("Alex"))
            }
            
            func checkObject(object: Any?) {
                let obj = object as? [String: Any]
                expect(obj?.keys.first).to(equal("name"))
                expect(obj?.values.first as? String).to(equal("Alex"))
            }
            
            it("serialize dictionary and entities inside it") {
                let dictionary = MaybeEmpty(["1":user, "2":user, "3":user])
                let serialized = dictionary.serialize() as! [String: Any]
                for (key, value) in serialized["value"] as! [String: Any] {
                    expect(key).notTo(beNil())
                    checkObject(value)
                }
            }
            
            it("recursively serialize dictionaries") {
                let dictionary = MaybeEmpty(["1":["1":user]])
                let serialized = dictionary.serialize() as! [String: Any]
                let value = serialized["value"] as! [String: Any]
                let innerDict = value["1"] as! [String: Any]
                for (key, value) in innerDict {
                    expect(key).notTo(beNil())
                    checkObject(value)
                }
            }
        }
        
        describe("Property policy serialization") { 
            it("is not serialized if nil") {
                let empty = MaybeEmpty(IgnorableNilProperty<Int>(nil))
                let serialized = empty.serialize() as! [String: Any]
                expect(serialized.count).to(be(0))
            }
            
            it("is serialized if not nil") {
                let notEmpty = MaybeEmpty(IgnorableNilProperty(1))
                let serialized = notEmpty.serialize() as! [String: Any]
                let value = serialized["value"] as? Int
                expect(value).to(be(1))
            }
            
            it("recursively serialize the object if needed") {
                let notEmpty = MaybeEmpty(IgnorableNilProperty(user))
                let serialized = notEmpty.serialize() as! [String: Any]
                let value = serialized["value"] as? [String: Any]
                expect(value?["name"] as? String).to(equal("Alex"))
            }

            it("recursively serialize IgnorableNilProperties") {
                let notEmpty = MaybeEmpty(IgnorableNilProperty(IgnorableNilProperty(1)))
                let serialized = notEmpty.serialize() as! [String: Any]
                let value = serialized["value"] as? Int
                expect(value).to(be(1))
            }
        }
        
        describe("Optional property serialization") {

            it("should serialize the object if it is an entry point") {
                let serialized = Optional(user).serialize() as! [String: Any]
                expect(serialized["name"] as? String).to(equal("Alex"))
            }
            
            it("serialize nil") {
                let nilInt: Int? = nil
                let optional = MaybeEmpty(nilInt)
                let serialized = optional.serialize() as! [String: Any]
                expect(serialized["value"] as? NSNull).to(be(NSNull()))
            }
            
            it("serialize an optional") {
                let optional = MaybeEmpty(Optional.Some(1))
                let serialized = optional.serialize() as! [String: Any] as? [String: Int]
                expect(serialized?["value"]).to(be(1))
            }
            
            it("recursively serialize the value") {
                let optional = MaybeEmpty(Optional.Some(user))
                let serialized = optional.serialize() as! [String: Any]
                let value = serialized["value"] as? [String: Any]
                expect(value?["name"] as? String).to(equal("Alex"))
            }
            
            it("recursively serialize Optionals") {
                let optional = MaybeEmpty(Optional.Some(Optional.Some(1)))
                let serialized = optional.serialize() as! [String: Any] as? [String: Int]
                expect(serialized?["value"]).to(be(1))
            }
        }
    }
}