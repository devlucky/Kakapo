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
        let id: Int
        let name: String
    }
    
    struct User: JSONAPIEntity {
        let id: Int
        let name: String
        let dog: Dog
    }
    
    struct Post: JSONAPIEntity {
        let id: Int
        let relatedPostIds: [Int]
    }
    
    override func spec() {
        
        let user = User(id: 11, name: "Alex", dog: Dog(id: 22, name: "Joan"))

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
                expect(attributes["id"].stringValue).to(beNil())
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
                let object = json(Post(id: 11, relatedPostIds: [1, 2, 3]))
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
        }
        
        describe("JSON API Entity with PropertyPolicies") {
            // TODO: ....
        }
        
        describe("JSON API  Entity relationship serialization") {
            it("should serialzie the relationships when they are single JSONAPIEntities") {
                
            }
            
            it("should serialzie the relationships when they are arrays of JSONAPIEntities") {
                
            }
            
            it("should not serialzie relationships of relationships") {
                
            }
            
            it("should serialzie the relationships even when an array is empty") {
                
            }
            
            it("should not serialzie nil relationships") {
                
            }
        }
    }
}