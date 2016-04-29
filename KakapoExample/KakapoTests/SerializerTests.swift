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
                let serialized = user.serialize() as! [String: AnyObject]
                expect(serialized["name"] as? String).to(equal("Alex"))
            }
            
            it("serialize arrays") {
                let friend = Friend(friends: [user])
                let serialized = friend.serialize() as! [String: AnyObject]
                let friends = serialized["friends"] as? [AnyObject]
                let first = friends?.first as? [String: AnyObject]
                expect(first?.keys.first).to(equal("name"))
                expect(first?.values.first as? String).to(equal("Alex"))
                expect(friends?.count).to(be(1))
            }
        }
        
        describe("Array serialization") {
            
            it("should return an array as an entry point") {
                let serialized = [user].serialize() as! [AnyObject]
                let first = serialized.first as! [String: AnyObject]
                expect(first["name"] as? String).to(equal("Alex"))
            }
            
            func checkObject(object: AnyObject?) {
                let obj = object as? [String: AnyObject]
                expect(obj?.keys.first).to(equal("name"))
                expect(obj?.values.first as? String).to(equal("Alex"))
            }
            
            it("serialize arrays and entities inside it") {
                let friend = Friend(friends: [user, user, user])
                let serialized = friend.serialize() as! [String: AnyObject]
                let friends = serialized["friends"] as! [AnyObject]
                expect(friends.count).to(be(3))
                for friend in friends {
                    checkObject(friend)
                }
            }

            it("recursively serialize arrays") {
                let container = MaybeEmpty([[user]])
                let serialized = container.serialize() as! [String: AnyObject]
                let array = serialized["value"] as? [AnyObject]
                let innerArray = array?.first as? [AnyObject]
                checkObject(innerArray?.first)
            }
        }
        
        describe("Dictionary serialization") {
            
            it("should serialize a dictionary as an entry point") {
                let serialized = ["test": user].serialize() as! [String: AnyObject]
                let user = serialized["test"] as! [String: AnyObject]
                expect(user["name"] as? String).to(equal("Alex"))
            }
            
            func checkObject(object: AnyObject?) {
                let obj = object as? [String: AnyObject]
                expect(obj?.keys.first).to(equal("name"))
                expect(obj?.values.first as? String).to(equal("Alex"))
            }
            
            it("serialize dictionary and entities inside it") {
                let dictionary = MaybeEmpty(["1":user, "2":user, "3":user])
                let serialized = dictionary.serialize() as! [String: AnyObject]
                for (key, value) in serialized["value"] as! [String: AnyObject] {
                    expect(key).notTo(beNil())
                    checkObject(value)
                }
            }
            
            it("recursively serialize dictionaries") {
                let dictionary = MaybeEmpty(["1":["1":user]])
                let serialized = dictionary.serialize() as! [String: AnyObject]
                let value = serialized["value"] as! [String: AnyObject]
                let innerDict = value["1"] as! [String: AnyObject]
                for (key, value) in innerDict {
                    expect(key).notTo(beNil())
                    checkObject(value)
                }
            }
        }
        
        describe("Optional property serialization") {

            it("should serialize the object if it is an entry point") {
                let serialized = Optional(user).serialize() as! [String: AnyObject]
                expect(serialized["name"] as? String).to(equal("Alex"))
            }
            
            it("serialize nil") {
                let nilInt: Int? = nil
                let optional = MaybeEmpty(nilInt)
                let serialized = optional.serialize() as! [String: AnyObject]
                expect(serialized["value"]).to(beNil())
                expect(serialized.count).to(equal(0))
            }
            
            it("serialize an optional") {
                let optional = MaybeEmpty(Optional.Some(1))
                let serialized = optional.serialize() as! [String: AnyObject] as? [String: Int]
                expect(serialized?["value"]).to(equal(1))
            }
            
            it("recursively serialize the value") {
                let optional = MaybeEmpty(Optional(user))
                let serialized = optional.serialize() as! [String: AnyObject]
                let value = serialized["value"] as? [String: AnyObject]
                expect(value?["name"] as? String).to(equal("Alex"))
            }
            
            it("recursively serialize Optionals") {
                let optional = MaybeEmpty(Optional.Some(Optional.Some(1)))
                let serialized = optional.serialize() as! [String: AnyObject] as? [String: Int]
                expect(serialized?["value"]).to(be(1))
            }
        }
    }
}