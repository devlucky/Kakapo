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
import SwiftyJSON
@testable import Kakapo

struct UppercaseTransformer<Wrapped: Serializable>: SerializationTransformer {
    
    let wrapped: Wrapped
    
    func transform(key: String) -> String {
        return key.uppercased()
    }
}

struct LowercaseFirstCharacterTransformer<Wrapped: Serializable>: SerializationTransformer {
    
    let wrapped: Wrapped
    
    func transform(key: String) -> String {
        let characters = key
        let first = String(characters.prefix(1)).lowercased()
        let other = String(characters.dropFirst())
        return first + other
    }
}

class SerializationTransformerSpec: QuickSpec {
    
    private struct Labrador: JSONAPIEntity {
        let id: String
        let name: String
    }
    
    private struct JUser: JSONAPIEntity {
        let id: String
        let userName: String
        let labrador: Labrador
    }
    
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
        
        let user = User(name: "Alex")
        let friend = Friend(friends: [user])
        
        describe("Serialization Transformers") {
            it("transforms the keys of a Serializable objects") {
                let serialized = UppercaseTransformer(wrapped: friend).serialized() as! [String: AnyObject]
                let friends = serialized["FRIENDS"] as? [AnyObject]
                let first = friends?.first as? [String: AnyObject]
                expect(first?.keys.first).to(equal("NAME"))
            }
            
            it("should apply transformations in the right order") {
                do {
                    let wrapped = UppercaseTransformer(wrapped: friend)
                    let serialized = LowercaseFirstCharacterTransformer(wrapped: wrapped).serialized() as! [String: AnyObject]
                    let friends = serialized["fRIENDS"] as? [AnyObject]
                    let first = friends?.first as? [String: AnyObject]
                    expect(first?.keys.first).to(equal("nAME"))
                }
                
                do {
                    let wrapped = LowercaseFirstCharacterTransformer(wrapped: friend)
                    let serialized = UppercaseTransformer(wrapped: wrapped).serialized() as! [String: AnyObject]
                    let friends = serialized["FRIENDS"] as? [AnyObject]
                    let first = friends?.first as? [String: AnyObject]
                    expect(first?.keys.first).to(equal("NAME"))
                }
            }
        }
        
        describe("Snake Case Transformer") {
            let user = User(name: "Alex")
            let transformer = SnakecaseTransformer(user)
            
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
                let serialized = SnakecaseTransformer(snake).serialized() as? [String: AnyObject]
                expect(serialized?.keys.first).to(equal("the_snake_camel_friend"))
            }
        }
        
        // CustomSerializable objects need to handle key transformer themselves
        // every CustomSerializable in Kakapo must be tested here.
        describe("CustomSerializable needs to handle (or forward) key transformer themselves") {
            
            context("Optional") {
                it("should transform the keys") {
                    let object = Optional.some(friend)
                    let serialized = UppercaseTransformer(wrapped: object).serialized() as! [String: AnyObject]
                    expect(serialized["FRIENDS"]).toNot(beNil())
                }
            }
            
            context("PropertyPolicy") {
                it("should transform the keys") {
                    let object = PropertyPolicy.some(friend)
                    let serialized = UppercaseTransformer(wrapped: object).serialized() as! [String: AnyObject]
                    expect(serialized["FRIENDS"]).toNot(beNil())
                }
            }
            
            context("ResponseFieldsProvider") {
                it("should transform the keys") {
                    let object = Response(statusCode: 200, body: friend)
                    let serialized = UppercaseTransformer(wrapped: object).serialized() as! [String: AnyObject]
                    expect(serialized["FRIENDS"]).toNot(beNil())
                }
            }
            
            context("Array") {
                it("should transform the keys") {
                    let object = [friend]
                    let serialized = UppercaseTransformer(wrapped: object).serialized() as! [[String: AnyObject]]
                    expect(serialized.first?["FRIENDS"]).toNot(beNil())
                }
            }
            
            context("Dictionary") {
                it("should transform the keys") {
                    let object = ["lowercase": friend]
                    let serialized = UppercaseTransformer(wrapped: object).serialized() as! [String: [String: AnyObject]]
                    expect(serialized["LOWERCASE"]?["FRIENDS"]).toNot(beNil())
                }
            }
            
            context("JSON API") {
                it("should transform the keys") {
                    let labrador = Labrador(id: "22", name: "Joan")
                    let user = JUser(id: "11", userName: "Alex", labrador: labrador)
                    let serialized = SnakecaseTransformer(JSONAPISerializer(user)).serialized() as! [String: AnyObject]
                    let json = JSON(serialized)
                    
                    let data = json["data"].dictionaryValue
                    
                    do {
                        let attributes = data["attributes"]!.dictionaryValue
                        expect(attributes["user_name"]?.string).to(equal("Alex"))
                    }

                    do {
                        let relationships = data["relationships"]?.dictionaryValue
                        
                        let dog = relationships?["labrador"]?.dictionaryValue
                        let dogData = dog?["data"]?.dictionaryValue
                        expect(dogData?["id"]?.string).to(equal("22"))
                        expect(dogData?["type"]?.string).to(equal(Labrador.type))
                    }
                    
                    do {
                        let included = json["included"].arrayValue
                        let dog = included.first?.dictionaryValue
                        expect(dog?["id"]?.string).to(equal("22"))

                        let attributes = dog?["attributes"]?.dictionaryValue
                        expect(attributes?["name"]?.string).to(equal("Joan"))
                    }
                }
            }
            
            context("JSON API Links") {
                it("should transform the keys") {
                    let object = JSONAPILink.object(href: "test", meta: friend)
                    let serialized = UppercaseTransformer(wrapped: object).serialized() as! [String: AnyObject]
                    expect(serialized["href"]).toNot(beNil())
                    let meta = serialized["meta"] as? [String: AnyObject]
                    expect(meta?["FRIENDS"]).toNot(beNil())
                }
            }
        }
    }
}
