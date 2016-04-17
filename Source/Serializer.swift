//
//  Serializer.swift
//  KakapoExample
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
     
     - returns: You should return either another `Serializable` object (also `Array` or `Dictionary`) containing other Serializable objects or property list types that can be serialized into json (primitive types).
     */
    func customSerialize() -> AnyObject
}

extension Serializable {
    func serialize() -> AnyObject {
        if let object = self as? CustomSerializable {
            return object.customSerialize()
        }
        return Kakapo.serialize(self)
    }
}

extension Array: CustomSerializable {
    // Array is serialized by creating an Array of its objects serialized
    public func customSerialize() -> AnyObject {
        var array = [AnyObject]()
        for obj in self {
            array.append(serializeObject(obj))
        }
        return array
    }
}

extension Dictionary: CustomSerializable {
    // Dictionary is serialized by creating a Dictionary with the same keys and values serialized
    public func customSerialize() -> AnyObject {
        var dictionary = [String: AnyObject]()
        for (key, value) in self {
            assert(key is String, "key must be a String to be serialized to JSON")
            dictionary[key as! String] = serializeObject(value)
        }
        return dictionary
    }
}

extension Optional: CustomSerializable {
    // Optional serializes its inner object or NSNull if nil
    public func customSerialize() -> AnyObject {
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
    public func customSerialize() -> AnyObject {
        return serializeObject(_object)
    }
}

func toData(object: AnyObject) -> NSData? {
    if !NSJSONSerialization.isValidJSONObject(object) {
        return nil
    }
    return try? NSJSONSerialization.dataWithJSONObject(object, options: .PrettyPrinted)
}

private func serializeObject(value: Any) -> AnyObject {
    if let value = value as? Serializable {
        return value.serialize()
    } else {
        // At this point an object must be an AnyObject and probably also a property list object otherwise the json will fail later.
        return value as! AnyObject
    }
}

/**
 Serialize the object by mirroring it and using its properties as keys and serialize the values.
 It recursively serialize the objects until it reaches primitive types, or fails if not possible. The final objects must be primitive types (property list compatible) or the serialization will fail because it can't be represented by JSON. This means that a `Serializable` objects must make sure that their properties are all `Serializable` or primitive types.
 
 - parameter object: A Serializable object, not a `CustomSerializable`
 
 - returns: A serialized object that may be convered to JSON, usually Array or Dictionary
 */
private func serialize(object: Serializable) -> AnyObject {
    assert(!(object is CustomSerializable))

    var dictionary = [String: AnyObject]()
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
