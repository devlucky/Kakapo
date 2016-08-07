//
//  Serializer.swift
//  Kakapo
//
//  Created by Alex Manzella on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 *  A protocol to serialize types into JSON representations, the object will be Mirrored to be serialized. Use `CustomReflectable` if you need different behaviors or use `CustomSerializable`if it's not a valid option.
 */
public protocol Serializable {
    // empty protocol, marks that the object should be Mirrored to be serialized.
}

/**
 *  Conforming to `CustomSerializable` the object won't be Mirrored to be serialized, use it in case `CustomReflectable` is not a viable option. Array for example use this to return an Array with its serialized objects inside.
 */
public protocol CustomSerializable: Serializable {
    /**
     Serialize by returning a valid object

     - parameter keyTransformer: An Optional closure to transform the keys, for custom serializations the implementation must take care of transforming the keys. This closure, for example, is not nil when a `Serializable` object is wrapped in a `SerializationTransformer`, the wrapper object will expect `CustomSerializable` object to correctly handle the key transformation (see `SerializationTransformer`)

     - returns: You should return either another `Serializable` object (also `Array` or `Dictionary`) containing other Serializable objects or property list types that can be serialized into json (primitive types).
     */
    func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject?
}

public extension Serializable {
    func serialize(keyTransformer: KeyTransformer? = nil) -> AnyObject? {
        if let object = self as? CustomSerializable {
            return object.customSerialize(keyTransformer)
        }
        return Kakapo.serialize(self, keyTransformer: keyTransformer)
    }

    func toData() -> NSData? {
        guard let object = serialize() else { return nil }
        
        if !NSJSONSerialization.isValidJSONObject(object) {
            return nil
        }
        return try? NSJSONSerialization.dataWithJSONObject(object, options: .PrettyPrinted)
    }
}

extension Array: CustomSerializable {
    /// `Array` is serialized by returning an `Array` containing its serialized elements
    public func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
        return flatMap { (element) -> AnyObject? in
            return serializeObject(element, keyTransformer: keyTransformer)
        }
    }
}

extension Dictionary: CustomSerializable {
    /// `Dictionary` is serialized by creating a Dictionary with the same keys and values serialized
    public func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
        var dictionary = [String: AnyObject]()
        for (key, value) in self {
            assert(key is String, "key must be a String to be serialized to JSON")
            if let serialized = serializeObject(value, keyTransformer: keyTransformer), let key = key as? String {
                let transformedKey = keyTransformer?(key: key) ?? key
                dictionary[transformedKey] = serialized
            }
        }
        return dictionary
    }
}

extension Optional: CustomSerializable {
    /// `Optional` serializes its inner object or nil if nil
    public func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
        switch self {
        case let .Some(value):
            return serializeObject(value, keyTransformer: keyTransformer)
        default:
            return nil
        }
    }
}

extension PropertyPolicy {
    /// `PropertyPolicy` serializes as nil when `.None`, as `NSNull` when `.Null` or serialize the object for `.Some`
    public func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
        switch self {
        case .None:
            return nil
        case .Null:
            return NSNull()
        case let .Some(value):
            return serializeObject(value, keyTransformer: keyTransformer)
        }
    }
}

private func serializeObject(value: Any, keyTransformer: KeyTransformer?) -> AnyObject? {
    if let value = value as? Serializable {
        return value.serialize(keyTransformer)
    }
    
    // At this point an object must be an AnyObject and probably also a property list object otherwise the json will fail later.
    assert((value as? AnyObject) != nil)
    return value as? AnyObject
}

/**
 Serialize the object by mirroring it and using its properties as keys and serialize the values.
 It recursively serialize the objects until it reaches primitive types, or fails if not possible. The final objects must be primitive types (property list compatible) or the serialization will fail because it can't be represented by JSON. This means that a `Serializable` objects must make sure that their properties are all `Serializable` or primitive types.
 
 - parameter object: A Serializable object, not a `CustomSerializable`
 - parameter keyTransformer: The keyTransformer to be used, if not nil, to transform the keys of the json
 
 - returns: A serialized object that may be convered to JSON, usually Array or Dictionary
 */
private func serialize(object: Serializable, keyTransformer: KeyTransformer?) -> AnyObject {
    assert(!(object is CustomSerializable))

    var dictionary = [String: AnyObject]()
    let mirror = Mirror(reflecting: object)
    for child in mirror.children {
        if let label = child.label, let value = serializeObject(child.value, keyTransformer: keyTransformer) {
            let key = keyTransformer?(key: label) ?? label
            dictionary[key] = value
        }
    }
    
    return dictionary
}
