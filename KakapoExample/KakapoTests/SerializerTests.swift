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
                let ignorableProperty = IgnorableNilProperty<Int>(obj: nil)
                expect(ignorableProperty.shouldSerialize).to(beFalse())
            }
            
            it("is not nil") {
                let ignorableProperty = IgnorableNilProperty<Int>(obj: 1)
                expect(ignorableProperty.shouldSerialize).to(beTrue())
            }
        }
    }
}

class SerializeSpec: QuickSpec {
    
    struct User: KakapoSerializable {
        let name: String
    }
    
    struct Friend: KakapoSerializable {
        let friends: [User]
        let dictionary: [String: [User]]
        
        init(friends: [User]) {
            self.friends = friends
            self.dictionary = ["test": friends]
        }
    }
    
    struct MaybeEmpty: KakapoSerializable {
        let maybeIgnored: IgnorableNilProperty<Int>
    }
    
    struct Opt: KakapoSerializable {
        let optional: Int?
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
                let empty = MaybeEmpty(maybeIgnored: IgnorableNilProperty<Int>(obj: nil))
                let serialized = serialize(empty)
                expect(serialized.count).to(be(0))
            }
            
            it("is serialized if not nil") {
                let notEmpty = MaybeEmpty(maybeIgnored: IgnorableNilProperty<Int>(obj: 1))
                let serialized = serialize(notEmpty) as? [String: Int]
                expect(serialized?["maybeIgnored"]).to(be(1))
            }
        }
        
        describe("Optional property serialization") { 
            it("serialize nil") {
                let optional = Opt(optional: nil)
                let serialized = serialize(optional) as? [String: NSNull]
                expect(serialized?["optional"]).to(be(NSNull()))
            }
            
            it("serialize an optional") {
                let empty = MaybeEmpty(maybeIgnored: IgnorableNilProperty<Int>(obj: 1))
                let serialized = serialize(empty) as? [String: Int]
                expect(serialized?["maybeIgnored"]).to(be(1))
            }
        }
    }
}