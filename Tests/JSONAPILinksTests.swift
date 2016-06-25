//
//  JSONAPILinksTests.swift
//  Kakapo
//
//  Created by Joan Romano on 17/05/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Quick
import Nimble
import SwiftyJSON
@testable import Kakapo

class JSONAPILinksSpec: QuickSpec {
    
    struct Dog: JSONAPIEntity, JSONAPILinkedEntity {
        let id: String
        let name: String
        let cat: Cat?
        let links: [String : JSONAPILink]?
        let topLinks: [String : JSONAPILink]?
    }
    
    struct DogWithNoLinks: JSONAPIEntity, JSONAPILinkedEntity {
        let id: String
        let name: String
        let cat: Cat?
    }
    
    struct Cat: JSONAPIEntity, JSONAPILinkedEntity {
        let id: String
        let name: String
        let links: [String : JSONAPILink]?
        let topLinks: [String : JSONAPILink]?
    }
    
    struct User: JSONAPIEntity, JSONAPILinkedEntity {
        let id: String
        let name: String
        let dog: Dog
        let cats: [Cat]
        let links: [String : JSONAPILink]?
    }
    
    struct NoCatsUser: JSONAPIEntity, JSONAPILinkedEntity {
        let id: String
        let name: String
        let dog: DogWithNoLinks
        let links: [String : JSONAPILink]?
    }
    
    struct Meta: Serializable {
        let copyright = "Copyright 2015 Example Corp."
        let authors = ["Yehuda Katz", "Steve Klabnik","Dan Gebhardt","Tyler Kellen"]
    }
    
    override func spec() {
        
        func json(object: Serializable) -> JSON {
            return JSON(object.serialize()!)
        }
        
        describe("JSON API serializer") {
            let dog = Dog(id: "22",
                          name: "Joan",
                          cat: nil,
                          links: ["self": JSONAPILink.Simple(value: "selfish"),
                                  "related": JSONAPILink.Simple(value: "relatedish")],
                          topLinks: nil)
            
            it("should serialize data with links") {
                let object = json(JSONAPISerializer(dog, topLinks: ["test": JSONAPILink.Simple(value: "hello")]))
                let data = object["data"]["links"].dictionaryValue
                expect(data.count).toNot(equal(0))
                expect(data["self"]).to(equal("selfish"))
            }
            
            it("should serialize top level links") {
                let object = json(JSONAPISerializer(dog, topLinks: ["test": JSONAPILink.Simple(value: "hello"), "another": JSONAPILink.Object(href: "http://example.com/articles/1/comments", meta: Meta())]))
                let data = object["links"].dictionaryValue
                expect(data.count).toNot(equal(0))
                expect(data["test"]).to(equal("hello"))
                expect(data["another"]!["href"]).to(equal("http://example.com/articles/1/comments"))
                expect(data["another"]!["meta"]["authors"][0]).to(equal("Yehuda Katz"))
            }
        }
        
        describe("JSON API Entity links serialization") {
            let cats = [Cat(id: "33",
                            name: "Stancho",
                            links: nil,
                            topLinks: ["prev": JSONAPILink.Simple(value: "hello"),
                                       "next": JSONAPILink.Simple(value: "world")]),
                        Cat(id: "44",
                            name: "Hez",
                            links: ["test": JSONAPILink.Simple(value: "hello"),
                                    "another": JSONAPILink.Object(href: "http://example.com/articles/1/comments", meta: Meta())],
                            topLinks: ["first": JSONAPILink.Simple(value: "yeah"),
                                       "last": JSONAPILink.Simple(value: "text")])]
            let dog = Dog(id: "22",
                          name: "Joan",
                          cat: cats[0],
                          links: nil,
                          topLinks: ["testDog": JSONAPILink.Simple(value: "hello"),
                                  "anotherDog": JSONAPILink.Object(href: "http://example.com/articles/1/comments", meta: Meta())])
            let user = User(id: "11",
                            name: "Alex",
                            dog: dog,
                            cats: cats,
                            links: ["one": JSONAPILink.Simple(value: "hello"),
                                    "two": JSONAPILink.Object(href: "hello", meta: Meta())])
            
            let user2 = User(id: "39",
                            name: "Joro",
                            dog: dog,
                            cats: cats,
                            links: ["joroLinkOne": JSONAPILink.Simple(value: "hello"),
                                    "joroLinkTwo": JSONAPILink.Object(href: "hello", meta: Meta())])
            
            it("should serialize the links inside the top data object") {
                let object = json(user)
                let links = object["links"].dictionaryValue
                expect(links.count).toNot(equal(0))
                expect(links["one"]).to(equal("hello"))
                expect(links["two"]!["href"]).to(equal("hello"))
                expect(links["two"]!["meta"]["copyright"]).to(equal("Copyright 2015 Example Corp."))
            }
            
            it("should serialize the top links inside single relationships") {
                let object = json(user)
                let data = object["relationships"]["dog"]["links"].dictionaryValue
                expect(data.count).toNot(equal(0))
                expect(data["anotherDog"]!["href"]).to(equal("http://example.com/articles/1/comments"))
                expect(data["testDog"]).to(equal("hello"))
            }
            
            it("should serialize the top links inside multiple relationships") {
                let object = json(user)
                let data = object["relationships"]["cats"]["links"].dictionaryValue
                expect(data.count).toNot(equal(0))
                expect(data["prev"]).to(equal("hello"))
                expect(data["next"]).to(equal("world"))
                expect(data["first"]).to(equal("yeah"))
                expect(data["last"]).to(equal("text"))
            }
            
            it("should serialize the links inside included objects") {
                let object = json(JSONAPISerializer(user))
                let data = object["included"][2]["links"].dictionaryValue
                expect(data).toNot(beNil())
                expect(data["test"]).to(equal("hello"))
                expect(data["another"]!["href"]).to(equal("http://example.com/articles/1/comments"))
            }
            
            it("should serialize the links inside array of data objects") {
                let object = json(JSONAPISerializer([user, user2]))
                let firstData = object["data"][0]["links"]
                let secondData = object["data"][0]["links"]
                expect(firstData).toNot(beNil())
                expect(secondData).toNot(beNil())
            }
            
            it("should not serialize nil links") {
                let object = json(DogWithNoLinks(id: "213", name: "Hez", cat: cats[0]))
                expect(object["links"].count) == 0
            }
            
            it("should not serialize nil top links") {
                let newUser = NoCatsUser(id: "11",
                                         name: "Alex",
                                         dog: DogWithNoLinks(id: "213", name: "Hez", cat: cats[0]),
                                         links: ["one": JSONAPILink.Simple(value: "hello"),
                                    "two": JSONAPILink.Object(href: "hello", meta: Meta())])
                let object = json(newUser)
                let data = object["relationships"]["dog"]["links"]
                expect(data.count) == 0
            }
        }

    }

}
