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
    }
    
    struct User: JSONAPIEntity, JSONAPILinkedEntity {
        let id: String
        let name: String
        let dog: Dog
        let cats: [Cat]
        let links: [String : JSONAPILink]?
        let relationshipsLinks: [String : [String : JSONAPILink]]?
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
                                  "related": JSONAPILink.Simple(value: "relatedish")])
            
            it("should serialize data with links") {
                let object = json(JSONAPISerializer(dog, topLevelLinks: ["test": JSONAPILink.Simple(value: "hello")]))
                let links = object["data"]["links"].dictionaryValue
                expect(links.count) == 2
                expect(links["self"]).to(equal("selfish"))
            }
            
            it("should serialize top level links") {
                let topLevelLinks = ["test": JSONAPILink.Simple(value: "hello"),
                                     "another": JSONAPILink.Object(href: "http://example.com/articles/1/comments", meta: Meta())]
                let object = json(JSONAPISerializer(dog, topLevelLinks: topLevelLinks))
                let links = object["links"].dictionaryValue
                expect(links.count) == 2
                expect(links["test"]).to(equal("hello"))
                expect(links["another"]!["href"]).to(equal("http://example.com/articles/1/comments"))
                expect(links["another"]!["meta"]["authors"][0]).to(equal("Yehuda Katz"))
            }
        }
        
        describe("JSON API Entity links serialization") {
            let cats = [Cat(id: "33",
                            name: "Stancho",
                            links: nil),
                        Cat(id: "44",
                            name: "Hez",
                            links: ["test": JSONAPILink.Simple(value: "hello"),
                                    "another": JSONAPILink.Object(href: "http://example.com/articles/1/comments", meta: Meta())])]
            let dog = Dog(id: "22",
                          name: "Joan",
                          cat: cats[0],
                          links: nil)
            let user = User(id: "11",
                            name: "Alex",
                            dog: dog,
                            cats: cats,
                            links: ["one": JSONAPILink.Simple(value: "hello"),
                                    "two": JSONAPILink.Object(href: "hello", meta: Meta())],
                            relationshipsLinks: ["cats": ["prev": JSONAPILink.Simple(value: "hello"),
                                                          "next": JSONAPILink.Simple(value: "world"),
                                                          "first": JSONAPILink.Simple(value: "yeah"),
                                                          "last": JSONAPILink.Simple(value: "text")],
                                                 "dog": ["testDog": JSONAPILink.Simple(value: "hello"),
                                                         "anotherDog": JSONAPILink.Object(href: "http://example.com/articles/1/comments", meta: Meta())]])
            
            let user2 = User(id: "39",
                             name: "Joro",
                             dog: dog,
                             cats: cats,
                             links: ["joroLinkOne": JSONAPILink.Simple(value: "hello"),
                                    "joroLinkTwo": JSONAPILink.Object(href: "hello", meta: Meta())],
                             relationshipsLinks: nil)
            
            it("should serialize the links inside the top data object") {
                let object = json(user)
                let links = object["links"].dictionaryValue
                
                expect(links["one"]).to(equal("hello"))
                expect(links["two"]!["href"]).to(equal("hello"))
                expect(links["two"]!["meta"]["copyright"]).to(equal("Copyright 2015 Example Corp."))
            }
            
            it("should serialize the relationships links inside single relationships") {
                let object = json(user)
                let links = object["relationships"]["dog"]["links"].dictionaryValue
                
                expect(links["anotherDog"]!["href"]).to(equal("http://example.com/articles/1/comments"))
                expect(links["testDog"]).to(equal("hello"))
            }
            
            it("should serialize the relationships links inside multiple relationships") {
                let object = json(user)
                let links = object["relationships"]["cats"]["links"].dictionaryValue
                
                expect(links["prev"]).to(equal("hello"))
                expect(links["next"]).to(equal("world"))
                expect(links["first"]).to(equal("yeah"))
                expect(links["last"]).to(equal("text"))
            }
            
            it("should serialize the links inside included objects") {
                let object = json(JSONAPISerializer(user))
                let included = object["included"].arrayValue
                let cat2 = included.filter { (relationships) in
                    if relationships.dictionaryValue["id"]!.intValue == 44 {
                        return true
                    }
                    return false
                }.first!
                
                
                let links = cat2["links"].dictionaryValue
                expect(links).toNot(beNil())
                expect(links["test"]).to(equal("hello"))
                expect(links["another"]!["href"]).to(equal("http://example.com/articles/1/comments"))
            }
            
            it("should serialize the links inside array of data objects") {
                let object = json(JSONAPISerializer([user, user2]))
                let firstLinks = object["data"][0]["links"]
                let secondLinks = object["data"][0]["links"]
                expect(firstLinks).toNot(beNil())
                expect(secondLinks).toNot(beNil())
            }
            
            it("should not serialize nil links") {
                let object = json(DogWithNoLinks(id: "213", name: "Hez", cat: cats[0]))
                expect(object["links"].count) == 0
            }
            
            it("should not serialize nil relationships links") {
                let userLinks = [
                    "one": JSONAPILink.Simple(value: "hello"),
                    "two": JSONAPILink.Object(href: "hello", meta: Meta())
                ]
                
                let newUser = NoCatsUser(id: "11",
                                         name: "Alex",
                                         dog: DogWithNoLinks(id: "213", name: "Hez", cat: cats[0]),
                                         links: userLinks)
                
                let object = json(newUser)
                let links = object["relationships"]["dog"]["links"]
                expect(links.count) == 0
            }
            
            it("should not have links or relationshipsLinks attributes since they are links, not attributes") {
                let object = json(user)
                expect(object["attributes"]["links"]).to(beEmpty())
                expect(object["attributes"]["relationshipsLinks"]).to(beEmpty())
            }
        }
    }
}
