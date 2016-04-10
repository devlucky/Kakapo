//
//  Serializer.swift
//  KakapoExample
//
//  Created by Alex Manzella on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 *  A protocol to serialize types into JSON representations
 */
public protocol Serializable {
    // empty protocol, Object will be Mirrored
}

public protocol CustomSerializable: Serializable {
    /**
     Serialize by returning a valid object
     
     - returns: You should return either another `Serializable` object (also `Array` or `Dictionary`) containing other Serializable objects or property list types that can be serialized into json (primitive types).
     */
    func customSerialize() -> Any
}

extension Serializable {
    func serialize() -> Any {
        if let object = self as? CustomSerializable {
            return object.customSerialize()
        }
        return Kakapo.serialize(self)
    }
}

extension Array: CustomSerializable {
    // Array is serialized by creating an Array of its objects serialized
    public func customSerialize() -> Any {
        var array = [Any]()
        for obj in self {
            array.append(serializeObject(obj))
        }
        return array
    }
}

extension Dictionary: CustomSerializable {
    // Dictionary is serialized by creating a Dictionary with the same keys and values serialized
    public func customSerialize() -> Any {
        var dictionary = [Key: Any]()
        for (key, value) in self {
            dictionary[key] = serializeObject(value)
        }
        return dictionary
    }
}

extension Optional: CustomSerializable {
    // Optional serializes its inner object or NSNull if nil
    public func customSerialize() -> Any {
        switch self {
        case let .Some(value):
            return serializeObject(value)
        default:
            return NSNull()
        }
    }
}

extension _PropertyPolicy {
    // _PropertyPolicy serializes its inner object
    public func customSerialize() -> Any {
        return serializeObject(_object)
    }
}

private func serializeObject(value: Any) -> Any {
    if let value = value as? Serializable {
        return value.serialize()
    } else {
        // At this point an object must be an AnyObject and probably also a property list object otherwise the json will fail later.
        assert(value is AnyObject)
        return value
    }
}

/**
 Serialize the object by mirroring it and using its properties as keys and serialize the values (unless `shouldMirrorToSerialize` return `false` then the custom implementation of `serialize()` is used).
 It recursively serialize the objects until it reaches primitive types, or fails if not possible. The final objects must be primitive types (property list compatible) or the serialization will fail because it can't be represented by JSON. This means that a `Serializable` objects must make sure that their properties are all `Serializable` or primitive types.
 
 - parameter object: A Serializable object
 
 - returns: A serialized object that may be convered to JSON, usually Array or Dictionary
 */
private func serialize(object: Serializable) -> Any {
    assert(!(object is CustomSerializable))

    var dictionary = [String: Any]()
    let mirror = Mirror(reflecting: object)
    for child in mirror.children {
        if let label = child.label {
            if let value = child.value as? _PropertyPolicy {
                if value.shouldSerialize {
                    dictionary[label] = serializeObject(value._object)
                }
            } else {
                dictionary[label] = serializeObject(child.value)
            }
        }
    }
    
    return dictionary
}
