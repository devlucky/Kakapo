//
//  JSONAPITests.swift
//  KakapoExample
//
//  Created by Alex Manzella on 28/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Quick
import Nimble
import SwiftyJSON
@testable import Kakapo

class JSONAPISpec: QuickSpec {
    
    struct Dog: JSONAPIEntity {
        let id: String
        let name: String
        var chasingCat: Cat?
    }
    
    struct Cat: JSONAPIEntity {
        let id: String
        let name: String
    }
    
    struct User: JSONAPIEntity {
        let id: String
        let name: String
        let dog: Dog
        let cats: [Cat]
    }
    
    struct Post: JSONAPIEntity {
        let id: String
        let relatedPostIds: [Int]
    }
    
    struct CustomPost: JSONAPIEntity, CustomSerializable {
        let id: String
        let title: String
        
        func customSerialize() -> AnyObject {
            return ["foo": "bar"]
        }
    }
    
    override func spec() {
        
        let cats = [Cat(id: "33", name: "Stancho"), Cat(id: "44", name: "Hez")]
        let dog = Dog(id: "22", name: "Joan", chasingCat: cats[0])
        let user = User(id: "11", name: "Alex", dog: dog, cats: cats)
        let lonelyMax = User(id: "11", name: "Max", dog: dog, cats: [])
        
        func json(object: Serializable) -> JSON {
            return JSON(object.serialize())
        }
        
        describe("JSON API Serialzier") {
            it("should serialize data") {
                let object = json(JSONAPISerializer(user))
                let data = object["data"].dictionaryValue
                expect(data.count).toNot(equal(0))
            }
        }
        
        describe("JSON API Entity Serialization") {
            
            it("should serialize the attributes") {
                let object = json(user)
                let attributes = object["attributes"]
                expect(attributes["id"].string).to(beNil())
                expect(attributes["name"].stringValue).to(equal("Alex"))
                expect(attributes.dictionaryValue.count).to(equal(1))
            }
            
            it("should serialzie the id") {
                let object = json(user)
                expect(object["id"].stringValue).to(equal("11"))
            }
            
            it("should serialzie the type") {
                let object = json(user)
                expect(object["type"].stringValue).to(equal("user"))
            }
            
            it("should serialzie an arrays of non-JSONAPIEntities as an attribute") {
                let object = json(Post(id: "11", relatedPostIds: [1, 2, 3]))
                let relatedPostIds = object["attributes"]["relatedPostIds"].arrayValue
                expect(relatedPostIds.count).to(equal(3))
                expect(relatedPostIds[0]).to(equal(1))
                expect(relatedPostIds[1]).to(equal(2))
                expect(relatedPostIds[2]).to(equal(3))
            }
            
            it("should serialzie an array of JSONAPIEntities") {
                let objects = json([user, user]).arrayValue
                for object in objects {
                    expect(object["attributes"]["name"].stringValue).to(equal("Alex"))
                }
                
                expect(objects.count).to(equal(2))
            }
            
            it("should only serialzie actual attributes into attributes") {
                let object = json(lonelyMax)
                let lonelyMaxAttributes = object["attributes"].dictionaryValue
                expect(lonelyMaxAttributes.count).to(equal(1)) // only name should be here, no id, no cats
                expect(lonelyMaxAttributes["name"]).to(equal("Max"))
                expect(lonelyMaxAttributes["cats"]).to(beNil())
                expect(lonelyMaxAttributes["id"]).to(beNil())
            }
            
            it("should fail to serialize CustomSerializable entities") {
                // TODO: discuss because there is no way to prevent this and might be unexpected
                let object = json(CustomPost(id: "123", title: "Test"))
                expect(object["id"].string).to(beNil())
            }
        }
        
        describe("JSON API Entity with PropertyPolicies") {
            // TODO: ....
        }
        
        describe("JSON API Entity with Optionals") {
            // TODO: ....
        }
        
        describe("JSON API  Entity relationship serialization") {
            it("should serialzie the relationships when they are single JSONAPIEntities") {
                let object = json(user)
                let dog = object["relationships"]["dog"]["data"]
                expect(dog.dictionary).toNot(beNil())
                expect(dog["id"].stringValue).to(equal("22"))
                expect(dog["type"].stringValue).to(equal("dog"))
            }
            
            it("should serialzie the relationships when they are arrays of JSONAPIEntities") {
                let object = json(user)
                let cats = object["relationships"]["cats"]["data"].array!
                expect(cats.count).to(equal(2))
                expect(cats[0]["id"].stringValue).to(equal("33"))
                expect(cats[0]["type"].stringValue).to(equal("cat"))
                expect(cats[1]["id"].stringValue).to(equal("44"))
                expect(cats[1]["type"].stringValue).to(equal("cat"))
            }
            
            it("should not serialzie relationships of relationships") {
                let object = json(user)
                let dogData = object["relationships"]["dog"]["data"].dictionary
                expect(dogData).toNot(beNil())
                expect(dogData?["relationships"]).to(beNil())
            }
            
            it("should not serialzie nil relationships") {
                let object = json(dog)
                let cat = object["relationships"].dictionaryValue
                expect(cat["chasingCat"]).to(beNil())
            }
            
            it("should serialzie the relationships even when an array is empty") {
                let object = json(lonelyMax)
                let cats = object["relationships"]["cats"].dictionary!
                expect(cats.count).to(equal(1))
                let dataArray = cats["data"]
                expect(dataArray).toNot(beNil())
                expect(dataArray?.count).to(equal(0))
            }
        }
    }
}