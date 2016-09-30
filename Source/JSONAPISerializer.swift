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
     
     - parameter includingRelationships: Defines if it should include the `relationships` field
     - parameter includingAttributes:    Defines if it should include the `attributes` field
     - parameter keyTransformer:       The keyTransformer to be used, if not nil, to transform the keys of the json
     
     - returns: Return an object representing the `data` field conforming to JSON API, for `JSONAPIEntity` boxes the return type will be used to fill the `relationships` field otherwise, when nil, the box will be serialized normally and used for the `attributes` field.
     */
    func data(includingRelationships: Bool, includingAttributes: Bool, transformingKeys keyTransformer: KeyTransformer?) -> Any?
    
    /**
     Creates the `included` field by aggregating and unifying the attributes of the relationships recursively
     
     - parameter includingChildren: Include relationships of relationships recursively, by default `JSONAPISerializer` won't include children
     - parameter keyTransformer:  The keyTransformer to be used, if not nil, to transform the keys of the json

     - returns: An array of included relationsips or nil if no relationsips are incldued.
     */
    func includedRelationships(includingChildren: Bool, transformingKeys keyTransformer: KeyTransformer?) -> [Any]?
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

private typealias JSONAPIConvertible = JSONAPISerializable & Serializable

/// A wrapper struct that handles the serialization of the JSON API data field
private struct JSONAPIDataWrapper: CustomSerializable {
    let object: JSONAPIConvertible
    
    fileprivate func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        return object.data(includingRelationships: true, includingAttributes: true, transformingKeys: keyTransformer)
    }
}

/// A wrapper struct that handles the serialization of the JSON API include field
private struct JSONAPIIncludedWrapper: CustomSerializable {
    let object: JSONAPIConvertible
    let includingChildren: Bool
    
    fileprivate func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        return object.includedRelationships(includingChildren: includingChildren, transformingKeys: keyTransformer)?.unifiedIncludedRelationships()
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
    
    private static func commonInit(_ object: JSONAPIConvertible, topLevelLinks: [String: JSONAPILink]?, meta: Serializable?, includingChildren: Bool) -> JSONAPISerializerInit {
        return (
            data: JSONAPIDataWrapper(object: object),
            links: topLevelLinks,
            meta: meta,
            included: JSONAPIIncludedWrapper(object: object, includingChildren: includingChildren)
        )
    }
    
    /**
     Initialize a serializer with a single `JSONAPIEntity`
     
     - parameter object: A `JSONAPIEntities`
     - parameter topLevelLinks: A top `JSONAPILink` optional object
     - parameter topLevelMeta: A meta object that will be serialized and placed in the top level of the json.
     - parameter includingChildren: when true it will include relationships of relationships, false by default.

     - returns: A serializable object that serializes a `JSONAPIEntity` conforming to JSON API
     */
    public init(_ object: T, topLevelLinks: [String: JSONAPILink]? = nil, topLevelMeta: Serializable? = nil, includingChildren: Bool = false) {
        (data, links, meta, included) = JSONAPISerializer.commonInit(object, topLevelLinks: topLevelLinks, meta: topLevelMeta, includingChildren: includingChildren)
    }
    
    /**
     Initialize a serializer with an array of `JSONAPIEntity`
     
     - parameter objects: An array of `JSONAPIEntity`
     - parameter topLevelLinks: A top `JSONAPILink` optional object
     - parameter topLevelMeta: A meta object that will be serialized and placed in the top level of the json.
     - parameter includingChildren: when true it wll include relationships of relationships, false by default.

     - returns: A serializable object that serializes an array of `JSONAPIEntity` conforming to JSON API
     */
    public init(_ objects: [T], topLevelLinks: [String: JSONAPILink]? = nil, topLevelMeta: Serializable? = nil, includingChildren: Bool = false) {
        (data, links, meta, included) = JSONAPISerializer.commonInit(objects, topLevelLinks: topLevelLinks, meta: topLevelMeta, includingChildren: includingChildren)
    }
}

// MARK: - Extensions

extension Array: JSONAPISerializable {
    
    // MARK: JSONAPISerializable
    
    /// return the result of recursively forwarding the function to its elements if the associatedtype is JSONAPISerializable, otherwise returns nil
    public func data(includingRelationships: Bool, includingAttributes: Bool, transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        return Element.self is JSONAPISerializable.Type ? flatMap { ($0 as? JSONAPISerializable)?.data(includingRelationships: includingRelationships, includingAttributes: includingAttributes, transformingKeys: keyTransformer) } : nil
    }
    
    /// return the result of recursively forwarding the function to its elements if the associatedtype is JSONAPISerializable, otherwise returns nil
    public func includedRelationships(includingChildren: Bool, transformingKeys keyTransformer: KeyTransformer?) -> [Any]? {
        guard Element.self is JSONAPISerializable.Type else { return nil }
        let includedRelationships = flatMap { ($0 as? JSONAPISerializable)?.includedRelationships(includingChildren: includingChildren, transformingKeys: keyTransformer) }.flatMap { $0 }
        return includedRelationships.isEmpty ? nil : includedRelationships
    }
    
    fileprivate func unifiedIncludedRelationships() -> [Any] {
        var dictionary = [String: Any]()
        
        forEach { (obj) in
            guard let relationship = obj as? [String: Any],
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
        case let .some(value):
            return value as? JSONAPISerializable
        case .none, .null:
            return nil
        }
    }
    
    // MARK: JSONAPISerializable
    
    /// return nil when `.none` or if the associated type is not `JSONAPISerializable`, an empty dictionary for `.null` and calls `data(includeRelationships:includeAttributes:)` functions on the wrapped object for `.some`
    public func data(includingRelationships: Bool, includingAttributes: Bool, transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        guard Wrapped.self is JSONAPISerializable.Type else {
            return nil
        }
        
        switch self {
        case let .some(value):
            if let value = value as? JSONAPISerializable {
                return value.data(includingRelationships: includingRelationships, includingAttributes: includingAttributes, transformingKeys: keyTransformer)
            }
            
        case .null:
            return [String: AnyObject]() // included as relationship but empty
        case .none:
            return nil
        }
        
        return nil
    }
    
    /// return nil when `.none`, `.null` or if the associated type is not `JSONAPISerializable`, calls `includedRelationships(includeChildren:keyTransformer:)` functions on the wrapped object for `.some`
    public func includedRelationships(includingChildren: Bool, transformingKeys keyTransformer: KeyTransformer?) -> [Any]? {
        return wrapped?.includedRelationships(includingChildren: includingChildren, transformingKeys: keyTransformer)
    }
}

extension Optional: JSONAPISerializable {
    
    private var wrapped: JSONAPISerializable? {
        guard Wrapped.self is JSONAPISerializable.Type else {
            return nil
        }
        
        switch self {
        case let .some(value):
            return value as? JSONAPISerializable
        case .none:
            return nil
        }
    }
    
    // MARK: JSONAPISerializable
    
    /// `Optional` returns the result of forwarding the function to its wrapped object in any, otherwise returns nil
    public func data(includingRelationships: Bool, includingAttributes: Bool, transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        return wrapped?.data(includingRelationships: includingRelationships, includingAttributes: includingAttributes, transformingKeys: keyTransformer)
    }
    
    /// `Optional` returns the result of forwarding the function to its wrapped object in any, otherwise returns nil
    public func includedRelationships(includingChildren: Bool, transformingKeys keyTransformer: KeyTransformer?) -> [Any]? {
        return wrapped?.includedRelationships(includingChildren: includingChildren, transformingKeys: keyTransformer)
    }
}

public extension JSONAPIEntity {
    
    // MARK: JSONAPIEntity

    /// returns the lower-cased class name as string by default
    static var type: String {
        return String(describing: self).lowercased()
    }
    
    // MARK: CustomSerializable
    
    /// returns the `data` field of the `JSONAPIEntity`
    public func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        return data(includingRelationships: true, includingAttributes: true, transformingKeys: keyTransformer)
    }
    
    // MARK: JSONAPISerializable
    
    /// returns the `data` field conforming to JSON API
    public func data(includingRelationships: Bool, includingAttributes: Bool, transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        var data = [String: Any]()
        let transformed: (String) -> (String) = { (key) in
            return keyTransformer?(key) ?? key
        }
        
        data["id"] = id
        data["type"] = Self.type
        
        guard includingRelationships || includingAttributes else {
            return data
        }
        
        let mirror = Mirror(reflecting: self)
        
        var attributes = [String: Any]()
        var relationships = [String: Any]()
        
        if let entityLinks = (self as? JSONAPILinkedEntity)?.links, !entityLinks.isEmpty {
            data["links"] = entityLinks.serialized(transformingKeys: keyTransformer)
        }
        
        let excludedKeys: Set<String> = ["id", "links", "relationshipsLinks"]
        
        for child in mirror.children {
            if let label = child.label {
                if let value = child.value as? JSONAPISerializable,
                    let data = value.data(includingRelationships: false, includingAttributes: false, transformingKeys: keyTransformer) {
                    if includingRelationships {
                        var relationship: [String: Any] = ["data" : data]
                        
                        if let linkedEntity = self as? JSONAPILinkedEntity,
                            let relationshipsLinks = linkedEntity.relationshipsLinks?[label], !relationshipsLinks.isEmpty {
                            relationship["links"] = relationshipsLinks.serialized(transformingKeys: keyTransformer)
                        }
                        
                        relationships[transformed(label)] = relationship
                    }
                } else if includingAttributes && !excludedKeys.contains(label) {
                    if let value = child.value as? Serializable {
                        attributes[transformed(label)] = value.serialized(transformingKeys: keyTransformer)
                    } else {
                        attributes[transformed(label)] = child.value
                    }
                }
            }
        }
        
        data["attributes"] = attributes.isEmpty ? nil : attributes
        data["relationships"] = relationships.isEmpty ? nil : relationships

        return data
    }
    
    /// returns the `included` relationships field conforming to JSON API
    public func includedRelationships(includingChildren: Bool, transformingKeys keyTransformer: KeyTransformer?) -> [Any]? {
        let mirror = Mirror(reflecting: self)
        let includedRelationships = mirror.children.flatMap { (label, value) -> [Any] in
            
            guard let value = value as? JSONAPISerializable,
                let include = value.data(includingRelationships: false, includingAttributes: true, transformingKeys: keyTransformer) else {
                return []
            }
            
            let relationships: [Any] = {
                if let include = include as? [Any] {
                    return include
                }
                
                return [include]
            }()
            
            if includingChildren, let childRelationships = value.includedRelationships(includingChildren: includingChildren, transformingKeys: keyTransformer) {
                return childRelationships + relationships
            }
            
            return relationships
        }
        
        return includedRelationships.isEmpty ? nil : includedRelationships
    }
}
