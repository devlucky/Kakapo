//
//  JSONAPISerializer.swift
//  Kakapo
//
//  Created by Alex Manzella on 28/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/// A protocol to serialize entities conforming to JSON API or to create JSON API Relationship boxes
public protocol JSONAPISerializable {
    /**
     Builds the `data` field conforming to JSON API, this protocol can be used to create boxes for `JSONAPIEntity` that are possibly detected as relationships.
     For example Array implement this method by returning nil when its `Element` is not conforming to `JSONAPISerializable` otherwise an array containing the data of its objects.
     
     - parameter includeRelationships: Defines if it should include the `relationships` field
     - parameter includeAttributes:    Defines if it should include the `attributes` field
     - parameter keyTransformer:       The keyTransformer to be used, if not nil, to transform the keys of the json
     
     - returns: Return an object representing the `data` field conforming to JSON API, for `JSONAPIEntity` boxes the return type will be used to fill the `relationships` field otherwise, when nil, the box will be serialized normally and used for the `attributes` field.
     */
    func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool, keyTransformer: KeyTransformer?) -> AnyObject?
    
    /**
     Creates the `included` field by aggregating and unifying the attributes of the relationships recursively
     
     - parameter includeChildren: Include relationships of relationships recursively, by default `JSONAPISerializer` won't include children
     - parameter keyTransformer:  The keyTransformer to be used, if not nil, to transform the keys of the json

     - returns: An array of included relationsips or nil if no relationsips are incldued.
     */
    func includedRelationships(includeChildren: Bool, keyTransformer: KeyTransformer?) -> [AnyObject]?
}

/**
 *  A JSON API entity, conforming to this protocol will change the behavior of serialization, `CustomSerializable` entities should not adopt this protocol because the default implementation would be overridden by their custom serialization.
 *  Relationships of an entity should also conform to this protocol.
 *  Properties recognized as relationships:
    - conforming to `JSONAPIEntity`
    - Array of `JSONAPIEntity`
    - Optional `JSONAPIEntity`
    - PropertyPolicy `JSONAPIEntity`
 
 * In general to be recognized as potential relationship or relationship wrapper (like `Array` or `Optional`) an object must conform to `JSONAPISerializable` and implement its methods.
 *  Relationships are automatically recognized using the static type of the property.
 *  For example an Array of `JSONAPIEntity` would be recognized as a relationship, also when empty, as soon as is static type at compile time is inferred correctly.
 
    ```swift
        struct User: JSONAPIEntity {
            let friends: [Friend] // correct if friend is JSONAPIEntity
            let enemies: [Any] // incorrect, Any is not JSONAPIEntity so this property is an attribute instead of a relationship
        }
    ```
 
 * The result of serialization is a dictionary containing:
   1. `type`: the type of the entity
   2. `id`: the id of the entity
   3. `attributes`: all the properties of the object excluding id, type and relationships. attributes might be absent if empty.
   4. `relationships`: all the properties that conform to JSONAPIEntity or array of JSONAPIEntity are recognized as relationships.
 
 * Note: When `JSONAPIEntity` is serialized as relationship only `id` and `type` will be included.
 
 * [See the JSON API documentation](http://jsonapi.org/format/#document-resource-objects)
 */
public protocol JSONAPIEntity: CustomSerializable, JSONAPISerializable {
    /// The type of this entity, by default the lowercase class name is used.
    static var type: String { get }
    /// The id of the entity
    var id: String { get }
}

private typealias JSONAPIConvertible = protocol<JSONAPISerializable, Serializable>

/// A wrapper struct that handles the serialization of the JSON API data field
private struct JSONAPIDataWrapper: CustomSerializable {
    let object: JSONAPIConvertible
    
    private func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
        return object.data(includeRelationships: true, includeAttributes: true, keyTransformer: keyTransformer)
    }
}

/// A wrapper struct that handles the serialization of the JSON API include field
private struct JSONAPIIncludedWrapper: CustomSerializable {
    let object: JSONAPIConvertible
    let includeChildren: Bool
    
    private func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
        return object.includedRelationships(includeChildren, keyTransformer: keyTransformer)?.unifiedIncludedRelationships()
    }
}

/**
 *  An object responsible to serialize a `JSONAPIEntity` or an array of `JSONAPIEntity` conforming to JSON API
 */
public struct JSONAPISerializer<T: JSONAPIEntity>: Serializable {

    /// Top level [`data`](http://jsonapi.org/format/#document-top-level) member: the document’s “primary data”
    private let data: JSONAPIDataWrapper

    /// Top level `included` member: an array of resource objects that are related to the primary data and/or each other (“included resources”).
    private let included: JSONAPIIncludedWrapper

    /// Top level [`links`](http://jsonapi.org/format/#document-links) member: a links object related to the primary data.
    private let links: [String: JSONAPILink]?

    /// Top level [`meta`](http://jsonapi.org/format/#document-meta) member: used to include non-standard meta-information.
    private let meta: Serializable?

    private typealias JSONAPISerializerInit = (data: JSONAPIDataWrapper, links: [String: JSONAPILink]?, meta: Serializable?, included: JSONAPIIncludedWrapper)
    
    private static func commonInit(object: JSONAPIConvertible, topLevelLinks: [String: JSONAPILink]?, meta: Serializable?, includeChildren: Bool) -> JSONAPISerializerInit {
        return (
            data: JSONAPIDataWrapper(object: object),
            links: topLevelLinks,
            meta: meta,
            included: JSONAPIIncludedWrapper(object: object, includeChildren: includeChildren)
        )
    }
    
    /**
     Initialize a serializer with a single `JSONAPIEntity`
     
     - parameter object: A `JSONAPIEntities`
     - parameter topLevelLinks: A top `JSONAPILink` optional object
     - parameter topLevelMeta: A meta object that will be serialized and placed in the top level of the json.
     - parameter includeChildren: when true it will include relationships of relationships, false by default.

     - returns: A serializable object that serializes a `JSONAPIEntity` conforming to JSON API
     */
    public init(_ object: T, topLevelLinks: [String: JSONAPILink]? = nil, topLevelMeta: Serializable? = nil, includeChildren: Bool = false) {
        (data, links, meta, included) = JSONAPISerializer.commonInit(object, topLevelLinks: topLevelLinks, meta: topLevelMeta, includeChildren: includeChildren)
    }
    
    /**
     Initialize a serializer with an array of `JSONAPIEntity`
     
     - parameter objects: An array of `JSONAPIEntity`
     - parameter topLevelLinks: A top `JSONAPILink` optional object
     - parameter topLevelMeta: A meta object that will be serialized and placed in the top level of the json.
     - parameter includeChildren: when true it wll include relationships of relationships, false by default.

     - returns: A serializable object that serializes an array of `JSONAPIEntity` conforming to JSON API
     */
    public init(_ objects: [T], topLevelLinks: [String: JSONAPILink]? = nil, topLevelMeta: Serializable? = nil, includeChildren: Bool = false) {
        (data, links, meta, included) = JSONAPISerializer.commonInit(objects, topLevelLinks: topLevelLinks, meta: topLevelMeta, includeChildren: includeChildren)
    }
}

// MARK: - Extensions

extension Array: JSONAPISerializable {
    
    // MARK: JSONAPISerializable
    
    /// return the result of recursively forwarding the function to its elements if the associatedtype is JSONAPISerializable, otherwise returns nil
    public func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool, keyTransformer: KeyTransformer?) -> AnyObject? {
        return Element.self is JSONAPISerializable.Type ? flatMap { ($0 as? JSONAPISerializable)?.data(includeRelationships: includeRelationships, includeAttributes: includeAttributes, keyTransformer: keyTransformer) } : nil
    }
    
    /// return the result of recursively forwarding the function to its elements if the associatedtype is JSONAPISerializable, otherwise returns nil
    public func includedRelationships(includeChildren: Bool, keyTransformer: KeyTransformer?) -> [AnyObject]? {
        guard Element.self is JSONAPISerializable.Type else { return nil }
        return flatMap { ($0 as? JSONAPISerializable)?.includedRelationships(includeChildren, keyTransformer: keyTransformer) }.flatMap { $0 }
    }
    
    private func unifiedIncludedRelationships() -> [AnyObject] {
        var dictionary = [String: AnyObject]()
        
        forEach { (obj) in
            guard let relationship = obj as? [String: AnyObject],
            let key = relationship["id"] as? String,
            let type = relationship["type"] as? String else {
                return
            }
            
            dictionary[key + type] = relationship
        }
        
        return dictionary.map { $0.1 }
    }
}

extension PropertyPolicy: JSONAPISerializable {

    private var wrapped: JSONAPISerializable? {
        guard Wrapped.self is JSONAPISerializable.Type else {
            return nil
        }
        
        switch self {
        case let .Some(value):
            return value as? JSONAPISerializable
        case .None, .Null:
            return nil
        }
    }
    
    // MARK: JSONAPISerializable
    
    /// return nil when `.None` or if the associated type is not `JSONAPISerializable`, an empty dictionary for `.Null` and calls `data(includeRelationships:includeAttributes:)` functions on the wrapped object for `.Some`
    public func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool, keyTransformer: KeyTransformer?) -> AnyObject? {
        guard Wrapped.self is JSONAPISerializable.Type else {
            return nil
        }
        
        switch self {
        case let .Some(value):
            if let value = value as? JSONAPISerializable {
                return value.data(includeRelationships: includeRelationships, includeAttributes: includeAttributes, keyTransformer: keyTransformer)
            }
            
        case .Null:
            return [String: AnyObject]() // included as relationship but empty
        case .None:
            return nil
        }
        
        return nil
    }
    
    /// return nil when `.None`, `.Null` or if the associated type is not `JSONAPISerializable`, calls `includedRelationships(_:)` functions on the wrapped object for `.Some`
    public func includedRelationships(includeChildren: Bool, keyTransformer: KeyTransformer?) -> [AnyObject]? {
        return wrapped?.includedRelationships(includeChildren, keyTransformer: keyTransformer)
    }
}

extension Optional: JSONAPISerializable {
    
    private var wrapped: JSONAPISerializable? {
        guard Wrapped.self is JSONAPISerializable.Type else {
            return nil
        }
        
        switch self {
        case let .Some(value):
            return value as? JSONAPISerializable
        case .None:
            return nil
        }
    }
    
    // MARK: JSONAPISerializable
    
    /// `Optional` returns the result of forwarding the function to its wrapped object in any, otherwise returns nil
    public func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool, keyTransformer: KeyTransformer?) -> AnyObject? {
        return wrapped?.data(includeRelationships: includeRelationships, includeAttributes: includeAttributes, keyTransformer: keyTransformer)
    }
    
    /// `Optional` returns the result of forwarding the function to its wrapped object in any, otherwise returns nil
    public func includedRelationships(includeChildren: Bool, keyTransformer: KeyTransformer?) -> [AnyObject]? {
        return wrapped?.includedRelationships(includeChildren, keyTransformer: keyTransformer)
    }
}

public extension JSONAPIEntity {
    
    // MARK: JSONAPIEntity

    /// returns the lower-cased class name as string by default
    static var type: String {
        return String(self).lowercaseString
    }
    
    // MARK: CustomSerializable
    
    /// returns the `data` field of the `JSONAPIEntity`
    public func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
        return data(includeRelationships: true, includeAttributes: true, keyTransformer: keyTransformer)
    }
    
    // MARK: JSONAPISerializable
    
    /// returns the `data` field conforming to JSON API
    public func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool, keyTransformer: KeyTransformer?) -> AnyObject? {
        var data = [String: AnyObject]()
        let transformed: (String) -> (String) = { (key) in
            return keyTransformer?(key: key) ?? key
        }
        
        data["id"] = id
        data["type"] = Self.type
        
        guard includeRelationships || includeAttributes else {
            return data
        }
        
        let mirror = Mirror(reflecting: self)
        
        var attributes = [String: AnyObject]()
        var relationships = [String: AnyObject]()
        
        if let entityLinks = (self as? JSONAPILinkedEntity)?.links where !entityLinks.isEmpty {
            data["links"] = entityLinks.serialize(keyTransformer)
        }
        
        let excludedKeys: Set<String> = ["id", "links", "relationshipsLinks"]
        
        for child in mirror.children {
            if let label = child.label {
                if let value = child.value as? JSONAPISerializable,
                    let data = value.data(includeRelationships: false, includeAttributes: false, keyTransformer: keyTransformer) {
                    if includeRelationships {
                        var relationship: [String: AnyObject] = ["data" : data]
                        
                        if let linkedEntity = self as? JSONAPILinkedEntity,
                            relationshipsLinks = linkedEntity.relationshipsLinks?[label] where !relationshipsLinks.isEmpty {
                            relationship["links"] = relationshipsLinks.serialize(keyTransformer)
                        }
                        
                        relationships[transformed(label)] = relationship
                    }
                } else if includeAttributes && !excludedKeys.contains(label) {
                    if let value = child.value as? Serializable {
                        attributes[transformed(label)] = value.serialize(keyTransformer)
                    } else {
                        assert(child.value is AnyObject)
                        attributes[transformed(label)] = child.value as? AnyObject
                    }
                }
            }
        }
        
        data["attributes"] = attributes.isEmpty ? nil : attributes
        data["relationships"] = relationships.isEmpty ? nil : relationships

        return data
    }
    
    /// returns the `included` relationships field conforming to JSON API
    public func includedRelationships(includeChildren: Bool, keyTransformer: KeyTransformer?) -> [AnyObject]? {
        let mirror = Mirror(reflecting: self)
        let includedRelationships = mirror.children.flatMap { (label, value) -> [AnyObject] in
            
            guard let value = value as? JSONAPISerializable,
                let include = value.data(includeRelationships: false, includeAttributes: true, keyTransformer: keyTransformer) else {
                return []
            }
            
            let relationships: [AnyObject] = {
                if let include = include as? [AnyObject] {
                    return include
                }
                
                return [include]
            }()
            
            if includeChildren, let childRelationships = value.includedRelationships(includeChildren, keyTransformer: keyTransformer) {
                return childRelationships + relationships
            }
            
            return relationships
        }
        
        return includedRelationships.isEmpty ? nil : includedRelationships
    }
}
