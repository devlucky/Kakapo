//
//  SerializationTransformerTests.swift
//  Kakapo
//
//  Created by Alex Manzella on 27/06/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Kakapo

struct UppercaseTransformer<Wrapped: Serializable>: SerializationTransformer {
    
    let wrapped: Wrapped
    
    func transform(key key: String) -> String {
        return key.uppercaseString
    }
}

struct LowercaseFirstCharacterTransformer<Wrapped: Serializable>: SerializationTransformer {
    
    let wrapped: Wrapped
    
    func transform(key key: String) -> String {
        let characters = key.characters
        let first = String(characters.prefix(1)).lowercaseString
        let other = String(characters.dropFirst())
        return first + other
    }
}

class SerializationTransformerSpec: QuickSpec {
    
    struct User: Serializable {
        let name: String
    }
    
    struct Friend: Serializable {
        let friends: [User]
        
        init(friends: [User]) {
            self.friends = friends
        }
    }
    
    struct Snake: Serializable {
        let theSnakeCamelFriend: String
    }
    
    override func spec() {
        
        describe("Serialization Transformers") {
            it("transforms the keys of a serialized object") {
                let user = User(name: "Alex")
                let friend = Friend(friends: [user])
                let serialized = UppercaseTransformer(wrapped: friend).serialize() as! [String: AnyObject]
                let friends = serialized["FRIENDS"] as? [AnyObject]
                let first = friends?.first as? [String: AnyObject]
                expect(first?.keys.first).to(equal("NAME"))
            }
            
            it("should apply transformations in the right order") {
                let user = User(name: "Alex")
                let friend = Friend(friends: [user])
                
                do {
                    let serialized = LowercaseFirstCharacterTransformer(wrapped: UppercaseTransformer(wrapped: friend)).serialize() as! [String: AnyObject]
                    let friends = serialized["fRIENDS"] as? [AnyObject]
                    let first = friends?.first as? [String: AnyObject]
                    expect(first?.keys.first).to(equal("nAME"))
                }
                
                do {
                    let serialized = UppercaseTransformer(wrapped: LowercaseFirstCharacterTransformer(wrapped: friend)).serialize() as! [String: AnyObject]
                    let friends = serialized["FRIENDS"] as? [AnyObject]
                    let first = friends?.first as? [String: AnyObject]
                    expect(first?.keys.first).to(equal("NAME"))
                }
            }
        }
        
        describe("Snake Case Transformer") {
            let user = User(name: "Alex")
            let transformer = SnakecaseTransformer(wrapped: user)
            
            it("should prefix uppercase characters with _") {
                expect(transformer.transform(key: "userNameOfALuckyUser")).to(equal("user_name_of_a_lucky_user"))
            }
            
            it("should lowercase all characters") {
                expect(transformer.transform(key: "aLuckyUser")).to(equal("a_lucky_user"))
            }
            
            it("should not prepend _ to the first character when is uppercase") {
                expect(transformer.transform(key: "ALuckyUser")).to(equal("a_lucky_user"))
            }
            
            it("should not append _ to the last character when is uppercase") {
                expect(transformer.transform(key: "ALuckyUseR")).to(equal("a_lucky_use_r"))
            }
            
            it("should not touch non-camelCase strings") {
                expect(transformer.transform(key: "something")).to(equal("something"))
            }
            
            it("should transform correctly the wrapped object's keys") {
                let snake = Snake(theSnakeCamelFriend: "abc")
                let serialized = SnakecaseTransformer(wrapped: snake).serialize() as? [String: AnyObject]
                expect(serialized?.keys.first).to(equal("the_snake_camel_friend"))
            }
        }
        
        // CustomSerializable objects need to handle key transformer themselves
        // every CustomSerializable in Kakapo must be tested here.
        describe("CustomSerializable needs to handle (or forward) key transformer themselves") {
            
            context("JSON API") {
                // TODO:
            }
            
            context("Optional") {
                // TODO:
            }
            
            context("PropertyPolicy") {
                // TODO:
            }
            
            context("JSON API") {
                // TODO:
            }
        }
    }
}