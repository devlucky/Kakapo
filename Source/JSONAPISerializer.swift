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
     Builds the `data` field conforming to JSON API, this protocol can be used to create boxes for `JSONAPIEntity` that are possibly detected as relationships. For example Array implement this method by returning nil when its `Element` is not conforming to `JSONAPISerializable` otherwise an array containing the data of its objects.
     
     - parameter includeRelationships: Defines if it should include the `relationships` field
     - parameter includeAttributes:    Defines if it should include the `attributes` field
     
     - returns: Return an object representing the `data` field conforming to JSON API, for `JSONAPIEntity` boxes the return type will be used to fill the `relationships` field otherwise, when nil, the box will be serialized normally and used for the `attributes` field.
     */
    func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool) -> AnyObject?
    
    /**
     Creates the `included` field by aggregating and unifying the attributes of the relationships recursively
     
     - parameter includeChildren: Include relationships of relationships recursively, by default `JSONAPISerializer` won't include children

     - returns: An array of included relationsips or nil if no relationsips are incldued.
     */
    func includedRelationships(includeChildren: Bool) -> [AnyObject]?
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

/**
 *  An object responsible to serialize a `JSONAPIEntity` or an array of `JSONAPIEntity` conforming to JSON API
 */
public struct JSONAPISerializer<T: JSONAPIEntity>: Serializable {
    
    // Top level `data` member: the document’s “primary data”
    private let data: AnyObject

    // Top level `included` member: an array of resource objects that are related to the primary data and/or each other (“included resources”).
    private let included: [AnyObject]?

    // Top level `links` member: a links object related to the primary data.
    private let links: AnyObject?
    
    private typealias JSONAPIConvertible = protocol<JSONAPISerializable, Serializable>
    private typealias JSONAPISerializerInit = (data: AnyObject, links: AnyObject?, included: [AnyObject]?)
    
    private static func commonInit(object: JSONAPIConvertible, topLevelLinks: [String: JSONAPILink]?, includeChildren: Bool) -> JSONAPISerializerInit {
        return (
            data: object.serialize()!, // can't fail, JSONAPIEntity must always be serializable
            links: topLevelLinks.serialize(),
            included: object.includedRelationships(includeChildren)?.unifiedIncludedRelationships()
        )
    }
    
    /**
     Initialize a serializer with a single `JSONAPIEntity`
     
     - parameter object: A `JSONAPIEntities`
     - parameter topLevelLinks: A top `JSONAPILink` optional object
     - parameter includeChildren: when true it will include relationships of relationships, false by default.

     - returns: A serializable object that serializes a `JSONAPIEntity` conforming to JSON API
     */
    public init(_ object: T, topLevelLinks: [String: JSONAPILink]? = nil, includeChildren: Bool = false) {
        (data, links, included) = JSONAPISerializer.commonInit(object, topLevelLinks: topLevelLinks, includeChildren: includeChildren)
    }
    
    /**
     Initialize a serializer with an array of `JSONAPIEntity`
     
     - parameter objects: An array of `JSONAPIEntity`
     - parameter topLevelLinks: A top `JSONAPILink` optional object
     - parameter includeChildren: when true it wll include relationships of relationships, false by default.

     - returns: A serializable object that serializes an array of `JSONAPIEntity` conforming to JSON API
     */
    public init(_ objects: [T], topLevelLinks: [String: JSONAPILink]? = nil, includeChildren: Bool = false) {
        (data, links, included) = JSONAPISerializer.commonInit(objects, topLevelLinks: topLevelLinks, includeChildren: includeChildren)
    }
}

// MARK: - Extensions

extension Array: JSONAPISerializable {
    
    // MARK: JSONAPISerializable
    
    public func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool) -> AnyObject? {
        return Element.self is JSONAPISerializable.Type ? flatMap { ($0 as? JSONAPISerializable)?.data(includeRelationships: includeRelationships, includeAttributes: includeAttributes) } : nil
    }
    
    public func includedRelationships(includeChildren: Bool) -> [AnyObject]? {
        guard Element.self is JSONAPISerializable.Type else { return nil }
        return flatMap { ($0 as? JSONAPISerializable)?.includedRelationships(includeChildren) }.flatMap { $0 }
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
    
    public func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool) -> AnyObject? {
        guard Wrapped.self is JSONAPISerializable.Type else {
            return nil
        }
        
        switch self {
        case let .Some(value):
            if let value = value as? JSONAPISerializable {
                return value.data(includeRelationships: includeRelationships, includeAttributes: includeAttributes)
            }
            
        case .Null:
            return [String: AnyObject]() // included as relationship but empty
        case .None:
            return nil
        }
        
        return nil
    }
    
    public func includedRelationships(includeChildren: Bool) -> [AnyObject]? {
        return wrapped?.includedRelationships(includeChildren)
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
    
    public func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool) -> AnyObject? {
        return wrapped?.data(includeRelationships: includeRelationships, includeAttributes: includeAttributes)
    }
    
    public func includedRelationships(includeChildren: Bool) -> [AnyObject]? {
        return wrapped?.includedRelationships(includeChildren)
    }
}

public extension JSONAPIEntity {
    
    // MARK: JSONAPIEntity

    static var type: String {
        return String(self).lowercaseString
    }
    
    // MARK: CustomSerializable

    public func customSerialize() -> AnyObject? {
        return data(includeRelationships: true, includeAttributes: true)!
    }
    
    // MARK: JSONAPISerializable

    public func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool) -> AnyObject? {
        var data = [String: AnyObject]()
        
        data["id"] = id
        data["type"] = Self.type
        
        guard includeRelationships || includeAttributes else {
            return data
        }
        
        let mirror = Mirror(reflecting: self)
        
        var attributes = [String: AnyObject]()
        var relationships = [String: AnyObject]()
        
        if let linkedEntity = self as? JSONAPILinkedEntity,
               entityLinks = linkedEntity.links where entityLinks.count > 0 {
            data["links"] = entityLinks.serialize()
        }
        
        let excludedKeys: Set<String> = ["id", "links", "topLinks"]
        
        for child in mirror.children {
            if let label = child.label {
                if let value = child.value as? JSONAPISerializable, let data = value.data(includeRelationships: false, includeAttributes: false) {
                    if includeRelationships {
                        var relationship: [String: AnyObject] = ["data" : data]
                        
                        if let linkedEntity = self as? JSONAPILinkedEntity,
                               relationshipsLinks = linkedEntity.relationshipsLinks?[label] where relationshipsLinks.count > 0 {
                            relationship["links"] = relationshipsLinks.serialize()
                        }
                        
                        relationships[label] = relationship
                    }
                } else if includeAttributes && !excludedKeys.contains(label)  {
                    if let value = child.value as? Serializable {
                        attributes[label] = value.serialize()
                    } else {
                        assert(child.value is AnyObject)
                        attributes[label] = child.value as? AnyObject
                    }
                }
            }
        }
        
        if includeAttributes && attributes.count > 0 {
            data["attributes"] = attributes
        }
        
        if includeRelationships && relationships.count > 0 {
            data["relationships"] = relationships
        }

        return data
    }
    
    public func includedRelationships(includeChildren: Bool) -> [AnyObject]? {
        let mirror = Mirror(reflecting: self)
        let includedRelationships = mirror.children.flatMap { (label, value) -> [AnyObject] in
            
            guard let value = value as? JSONAPISerializable,
                let include = value.data(includeRelationships: false, includeAttributes: true) else {
                return []
            }
            
            let relationships: [AnyObject] = {
                if let include = include as? [AnyObject] {
                    return include
                }
                
                return [include]
            }()
            
            if includeChildren, let childRelationships = value.includedRelationships(includeChildren) {
                return childRelationships + relationships
            }
            
            return relationships
        }
        
        return includedRelationships.count > 0 ? includedRelationships : nil
    }
}
