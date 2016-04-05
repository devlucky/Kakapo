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
        let dictionary: [String: [User]]
        
        init(friends: [User]) {
            self.friends = friends
            self.dictionary = ["test": friends]
        }
    }
    
    override func spec() {
        let user = User(name: "Alex")
        
        describe("Serialization of Serializable entities") {
            it("produce a dictionary where properties are keys and values are values") {
                let serialized = serialize(user)
                expect(serialized["name"] as? String).to(equal("Alex"))
            }
            
            it("serialize arrays") {
                let friend = Friend(friends: [user])
                let serialized = serialize(friend)
                let friends = serialized["friends"] as? [Any]
                let first = friends?.first as? [String: Any]
                expect(first?.keys.first).to(equal("name"))
                expect(first?.values.first as? String).to(equal("Alex"))
                expect(friends?.count).to(be(1))
            }
        }
        
        describe("recursive serialization") {
            func checkObject(objects: [Any]?) {
                let first = objects?.first as? [String: Any]
                expect(first?.keys.first).to(equal("name"))
                expect(first?.values.first as? String).to(equal("Alex"))
                expect(objects?.count).to(be(1))
            }
            
            it("serialize arrays and entities inside it") {
                let friend = Friend(friends: [user])
                let serialized = serialize(friend)
                let friends = serialized["friends"] as? [Any]
                checkObject(friends)
            }
            
            it("serialize dictionary and entities inside it") {
                let friend = Friend(friends: [user])
                let serialized = serialize(friend)
                let dictionary = serialized["dictionary"] as? [String: Any]
                let friends = dictionary?["test"] as? [Any]
                checkObject(friends)
            }
        }
        
        describe("Property policy serialization") { 
            it("is not serialized if nil") {
                let empty = MaybeEmpty(IgnorableNilProperty<Int>(nil))
                let serialized = serialize(empty)
                expect(serialized.count).to(be(0))
            }
            
            it("is serialized if not nil") {
                let notEmpty = MaybeEmpty(IgnorableNilProperty(1))
                let serialized = serialize(notEmpty)
                let value = serialized["value"] as? Int
                expect(value).to(be(1))
            }
            
            it("recursively serialize the object if needed") {
                let notEmpty = MaybeEmpty(IgnorableNilProperty(user))
                let serialized = serialize(notEmpty)
                let value = serialized["value"] as? [String: Any]
                expect(value?["name"] as? String).to(equal("Alex"))
            }

            it("recursively serialize IgnorableNilProperties") {
                let notEmpty = MaybeEmpty(IgnorableNilProperty(IgnorableNilProperty(1)))
                let serialized = serialize(notEmpty)
                let value = serialized["value"] as? Int
                expect(value).to(be(1))
            }
        }
        
        describe("Optional property serialization") { 
            it("serialize nil") {
                let nilInt: Int? = nil
                let optional = MaybeEmpty(nilInt)
                let serialized = serialize(optional)
                expect(serialized["value"] as? NSNull).to(be(NSNull()))
            }
            
            it("serialize an optional") {
                let optional = MaybeEmpty(Optional.Some(1))
                let serialized = serialize(optional) as? [String: Int]
                expect(serialized?["value"]).to(be(1))
            }
            
            it("recursively serialize the value") {
                let optional = MaybeEmpty(Optional.Some(user))
                let serialized = serialize(optional)
                let value = serialized["value"] as? [String: Any]
                expect(value?["name"] as? String).to(equal("Alex"))
            }
            
            it("recursively serialize Optionals") {
                let optional = MaybeEmpty(Optional.Some(Optional.Some(1)))
                let serialized = serialize(optional) as? [String: Int]
                expect(serialized?["value"]).to(be(1))
            }
        }
    }
}