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
    /**
     Serialize by returning a valid object
     
     - returns: You should return either another `Serializable` object (also `Array` or `Dictionary`) containing other Serializable objects or property list types that can be serialized into json (primitive types).
     */
    func serialize() -> Any
}

extension Serializable {
    func serialize() -> Any {
        return Kakapo.serialize(self)
    }
}

extension Array: Serializable {
    // Array is serialized by creating an Array of its objects serialized
    public func serialize() -> Any {
        var array = [Any]()
        for obj in self {
            array.append(serializeObject(obj))
        }
        return array
    }
}

extension Dictionary: Serializable {
    // Dictionary is serialized by creating a Dictionary with the same keys and values serialized
    public func serialize() -> Any {
        var dictionary = [Key: Any]()
        for (key, value) in self {
            dictionary[key] = serializeObject(value)
        }
        return dictionary
    }
}

extension Optional: Serializable {
    // Optional serializes its inner object or NSNull if nil
    public func serialize() -> Any {
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
    public func serialize() -> Any {
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
 Serialize the object by mirroring it and using its properties as keys and serialize the values.
 It recursively serialize the objects until it reaches primitive types, or fails if not possible. The final objects must be primitive types (property list compatible) or the serialization will fail because it can't be represented by JSON. This means that a `Serializable` objects must make sure that their properties are all `Serializable` or primitive types.
 
 - parameter object: A Serializable object
 
 - returns: An Dictionary that can be converted to JSON
 */
func serialize(object: Serializable) -> [String: Any] {
    // FIXME: Entry point can't be Array or Dictionary because their Mirror is not what we want. Use CustomReflectable entry points. [#14](https://github.com/devlucky/Kakapo/issues/14)
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
