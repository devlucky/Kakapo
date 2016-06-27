//
//  JSONAPILinks.swift
//  Kakapo
//
//  Created by Joan Romano on 19/06/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 * An enum representing JSON API Link types.
 
 * A link MUST be represented as either:
 
    - A string containing the link’s URL.
    - An object which can contain the following members:
        - `href`: a string containing the link’s URL.
        - `meta`: a meta object containing non-standard meta-information about the link.
 
 * [See the JSON API documentation on links](http://jsonapi.org/format/#document-links)
 */
public enum JSONAPILink: CustomSerializable {
    case Simple(value: String)
    case Object(href: String, meta: Serializable)
    
    public func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
        switch self {
        case let Object(href, meta):
            var serializedObject: [String: AnyObject] = ["href" : href]
            serializedObject["meta"] = meta.serialize(keyTransformer)
            
            return serializedObject
        case let Simple(value):
            return value
        }
    }
}

/**
 * A protocol representing a JSON API entity with links. This will handle all different `links` combinations:
 
 - Inside `data` field
 - Inside `included` field
 - Inside `relationships` field
 
 * For the first two options, an entity must use the `links` property. In order to add links in the `relationships` field,
 an entity must use `relationshipsLinks` property and return them for every relationship. For example, given the representation:
 
 ```swift
 struct Cat: JSONAPIEntity, JSONAPILinkedEntity {
    let id: String
    let name: String
    let links: [String : JSONAPILink]?
 }
 
 struct Dog: JSONAPIEntity, JSONAPILinkedEntity {
    let id: String
    let name: String
    let links: [String : JSONAPILink]?
 }
 
 struct User: JSONAPIEntity, JSONAPILinkedEntity {
    let id: String
    let name: String
    let cats: [Cat]
    let links: [String : JSONAPILink]?
    let relationshipsLinks: [String : [String : JSONAPILink]]?
 }
 ```
 
 Appart from their own entity links, and in order to provide extra links for relationships, `User` must specify them for each relationship key:
 
 ```swift
 let cats = [Cat(id: "33", name: "Stancho", links: nil),
             Cat(id: "44", name: "Hez", links: ["test": JSONAPILink.Simple(value: "hello"), 
                                                "another": JSONAPILink.Object(href: "http://example.com/articles/1/comments", meta: Meta())])]
 
 let dog = Dog(id: "22", name: "Joan", links: nil)
 
 let user = User(id: "11", name: "Alex", dog: dog, cats: cats, 
                 links: ["one": JSONAPILink.Simple(value: "hello"),
                         "two": JSONAPILink.Object(href: "hello", meta: Meta())],
                 relationshipsLinks: ["cats": ["prev": JSONAPILink.Simple(value: "hello"),
                                               "next": JSONAPILink.Simple(value: "world"),
                                               "first": JSONAPILink.Simple(value: "yeah"),
                                               "last": JSONAPILink.Simple(value: "text")],
                                      "dog": ["testDog": JSONAPILink.Simple(value: "hello"),
                                              "anotherDog": JSONAPILink.Object(href: "http://example.com/articles/1/comments", meta: Meta())]
                                     ]
            )
 ```
 
 * In order to represent the top level links of the root object, check out `JSONAPISerializer` initialization methods.
 
 * [See the JSON API documentation on links](http://jsonapi.org/format/#document-links)
 */
public protocol JSONAPILinkedEntity {
    var links: [String : JSONAPILink]? { get }
    var relationshipsLinks: [String : [String : JSONAPILink]]? { get }
}

extension JSONAPILinkedEntity {
    public var links: [String : JSONAPILink]? { return nil }
    public var relationshipsLinks: [String : [String : JSONAPILink]]? { return nil }
}
