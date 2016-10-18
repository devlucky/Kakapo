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
    func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any?
}

public extension Serializable {
    /**
     Serialize a `Serializable` object. The output, unless nil, is convertible to `Data` / JSON. Usually you don't need to use this method directly since `Router` will automatically serialize objects when needed.
     
     - parameter keyTransformer: A closure that given a key transforms it into another key. Usually this optional closure is provided by `SerializationTransformer` when a `Serializable` object is wrapped into a transformer.
     
     - returns: The serialized object
     */
    func serialized(transformingKeys keyTransformer: KeyTransformer? = nil) -> Any? {
        if let object = self as? CustomSerializable {
            return object.customSerialized(transformingKeys: keyTransformer)
        }
        return serialize(self, keyTransformer: keyTransformer)
    }

    /**
     Serialize a `Serializable` object and convert the serialized object to `Data`. Unless it is nil the return value is representing a JSON. Usually you don't need to use this method directly since `Router` will automatically serialize objects when needed.
     
     - returns: The serialized object as `Data`
     */
    func toData() -> Data? {
        guard let object = serialized() else { return nil }
        
        if !JSONSerialization.isValidJSONObject(object) {
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
    }
    
    fileprivate func serializeObject(_ value: Any, keyTransformer: KeyTransformer?) -> Any? {
        if let value = value as? Serializable {
            return value.serialized(transformingKeys: keyTransformer)
        }
        
        return value
    }
    
    /**
     Serialize the object by mirroring it and using its properties as keys and serialize the values.
     It recursively serialize the objects until it reaches primitive types, or fails if not possible. The final objects must be primitive types (property list compatible) or the serialization will fail because it can't be represented by JSON. This means that a `Serializable` objects must make sure that their properties are all `Serializable` or primitive types.
     
     - parameter object: A Serializable object, not a `CustomSerializable`
     - parameter keyTransformer: The keyTransformer to be used, if not nil, to transform the keys of the json
     
     - returns: A serialized object that may be converted to JSON, usually Array or Dictionary
     */
    private func serialize(_ object: Serializable, keyTransformer: KeyTransformer?) -> Any {
        assert((object is CustomSerializable) == false)
        
        var dictionary = [String: Any]()
        let mirror = Mirror(reflecting: object)
        for child in mirror.children {
            if let label = child.label, let value = serializeObject(child.value, keyTransformer: keyTransformer) {
                let key = keyTransformer?(label) ?? label
                dictionary[key] = value
            }
        }
        
        return dictionary
    }
}

extension Array: CustomSerializable {
    /// `Array` is serialized by returning an `Array` containing its serialized elements
    public func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        return flatMap { (element) -> Any? in
            return serializeObject(element, keyTransformer: keyTransformer)
        }
    }
}

extension Dictionary: CustomSerializable {
    /// `Dictionary` is serialized by creating a Dictionary with the same keys and values serialized
    public func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        var dictionary = [String: Any]()
        for (key, value) in self {
            assert(key is String, "key must be a String to be serialized to JSON")
            if let serialized = serializeObject(value, keyTransformer: keyTransformer), let key = key as? String {
                let transformedKey = keyTransformer?(key) ?? key
                dictionary[transformedKey] = serialized
            }
        }
        return dictionary
    }
}

extension Optional: CustomSerializable {
    /// `Optional` serializes its inner object or nil if nil
    public func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        switch self {
        case let .some(value):
            return serializeObject(value, keyTransformer: keyTransformer)
        default:
            return nil
        }
    }
}

extension PropertyPolicy {
    /// `PropertyPolicy` serializes as nil when `.none`, as `NSNull` when `.null` or serialize the object for `.some`
    public func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        switch self {
        case .none:
            return nil
        case .null:
            return NSNull()
        case let .some(value):
            return serializeObject(value, keyTransformer: keyTransformer)
        }
    }
}
