//
//  SerializerTests.swift
//  Kakapo
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
    
    init(_ value: T) {
        self.value = value
    }
}

class SerializeSpec: QuickSpec {
    
    struct User: Serializable {
        let name: String
    }
    
    struct CustomUser: CustomSerializable {
        let name: String
        
        func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
            let key = keyTransformer?("customName") ?? "customName"
            return [key: name]
        }
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
                let serialized = user.serialized() as! [String: AnyObject]
                expect(serialized["name"] as? String).to(equal("Alex"))
            }
            
            it("serialize arrays") {
                let friend = Friend(friends: [user])
                let serialized = friend.serialized() as! [String: AnyObject]
                let friends = serialized["friends"] as? [AnyObject]
                let first = friends?.first as? [String: AnyObject]
                expect(first?.keys.first).to(equal("name"))
                expect(first?.values.first as? String).to(equal("Alex"))
                expect(friends?.count) == 1
            }
            
            context("when object is CustomSerializable") {
                it("is correctly serialized using the custom serialization") {
                    let serialized = CustomUser(name: "Alex").serialized() as! [String: AnyObject]
                    expect(serialized["customName"] as? String).to(equal("Alex"))
                }
            }
        }
        
        describe("Array serialization") {
            
            it("should return an array as an entry point") {
                let serialized = [user].serialized() as! [AnyObject]
                let first = serialized.first as! [String: AnyObject]
                expect(first["name"] as? String).to(equal("Alex"))
            }
            
            func checkObject(_ object: AnyObject?) {
                let obj = object as? [String: AnyObject]
                expect(obj?.keys.first).to(equal("name"))
                expect(obj?.values.first as? String).to(equal("Alex"))
            }
            
            it("serialize arrays and entities inside it") {
                let friend = Friend(friends: [user, user, user])
                let serialized = friend.serialized() as! [String: AnyObject]
                let friends = serialized["friends"] as! [AnyObject]
                expect(friends.count) == 3
                for friend in friends {
                    checkObject(friend)
                }
            }

            it("recursively serialize arrays") {
                let container = MaybeEmpty([[user]])
                let serialized = container.serialized() as! [String: AnyObject]
                let array = serialized["value"] as? [AnyObject]
                let innerArray = array?.first as? [AnyObject]
                checkObject(innerArray?.first)
            }
        }
        
        describe("Dictionary serialization") {
            
            it("should serialize a dictionary as an entry point") {
                let serialized = ["test": user].serialized() as! [String: AnyObject]
                let user = serialized["test"] as! [String: AnyObject]
                expect(user["name"] as? String).to(equal("Alex"))
            }
            
            func checkObject(_ object: AnyObject?) {
                let obj = object as? [String: AnyObject]
                expect(obj?.keys.first).to(equal("name"))
                expect(obj?.values.first as? String).to(equal("Alex"))
            }
            
            it("serialize dictionary and entities inside it") {
                let dictionary = MaybeEmpty(["1": user, "2": user, "3": user])
                let serialized = dictionary.serialized() as! [String: AnyObject]
                for (key, value) in serialized["value"] as! [String: AnyObject] {
                    expect(key).notTo(beNil())
                    checkObject(value)
                }
            }
            
            it("recursively serialize dictionaries") {
                let dictionary = MaybeEmpty(["1": ["1": user]])
                let serialized = dictionary.serialized() as! [String: AnyObject]
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
                let serialized = Optional(user).serialized() as! [String: AnyObject]
                expect(serialized["name"] as? String).to(equal("Alex"))
            }
            
            it("serialize nil") {
                let nilInt: Int? = nil
                let optional = MaybeEmpty(nilInt)
                let serialized = optional.serialized() as! [String: AnyObject]
                expect(serialized["value"]).to(beNil())
                expect(serialized.count).to(equal(0))
            }
            
            it("produces nil data and serialized object when nil") {
                let nilInt: Int? = nil
                expect(nilInt.serialized()).to(beNil())
                expect(nilInt.toData()).to(beNil())
            }
            
            it("serialize an optional") {
                let optional = MaybeEmpty(Optional.some(1))
                let serialized = optional.serialized() as! [String: AnyObject] as? [String: Int]
                expect(serialized?["value"]).to(equal(1))
            }
            
            it("recursively serialize the value") {
                let optional = MaybeEmpty(Optional(user))
                let serialized = optional.serialized() as! [String: AnyObject]
                let value = serialized["value"] as? [String: AnyObject]
                expect(value?["name"] as? String).to(equal("Alex"))
            }
            
            it("recursively serialize Optionals") {
                let optional = MaybeEmpty(Optional.some(Optional.some(1)))
                let serialized = optional.serialized() as! [String: AnyObject] as? [String: Int]
                expect(serialized?["value"]) == 1
            }
        }
        
        describe("KeyTransformer") {
            let uppercased: (String) -> (String) = { $0.uppercased() }
            
            it("should handle the keyTransformer when serializing a Serializable object") {
                let serialized = user.serialized(transformingKeys: uppercased) as! [String: AnyObject]
                expect(serialized["NAME"] as? String).to(equal("Alex"))
            }
            
            it("should handle the keyTransformer when serializing a CustomSerializable object") {
                let serialized = CustomUser(name: "Alex").serialized(transformingKeys: uppercased) as! [String: AnyObject]
                expect(serialized["CUSTOMNAME"] as? String).to(equal("Alex"))
            }
        }
    }
}
