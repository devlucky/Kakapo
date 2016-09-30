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

    /** A string containing the link’s URL. */
    case simple(value: String)
    /**
     An object which can contain more information than the link itself
     
     - parameter href: a string containing the link’s URL.
     - parameter meta: a meta object containing non-standard meta-information about the link.
     */
    case object(href: String, meta: Serializable)
    
    // MARK: CustomSerializable
    
    /**
     The `JSONAPILink` implementation of `CustomSerializable` returns directly the link for `.simple` or returns a dictionary containing the link (href key) and the serialized meta object (meta key) for `.object`
     */
    public func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        switch self {
        case let .object(href, meta):
            var serializedObject: [String: Any] = ["href" : href]
            serializedObject["meta"] = meta.serialized(transformingKeys: keyTransformer)
            
            return serializedObject
        case let .simple(value):
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
 
 Apart from their own entity links, and in order to provide extra links for relationships, `User` must specify them for each relationship key:
 
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
    /// The related links, must use link-names as keys and links as values.
    var links: [String : JSONAPILink]? { get }
    /// The relationships links, an object containing relationships can specify top level links for every relationship type. The object must provide a Dictionary where keys are the relationships types and values are dictionaries with link-names as keys and link as values.
    var relationshipsLinks: [String : [String : JSONAPILink]]? { get }
}

extension JSONAPILinkedEntity {
    /// Default Implementation returns nil
    public var links: [String : JSONAPILink]? { return nil }
    /// Default Implementation returns nil
    public var relationshipsLinks: [String : [String : JSONAPILink]]? { return nil }
}
