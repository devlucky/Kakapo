//
//  Serializer.swift
//  KakapoExample
//
//  Created by Alex Manzella on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

public protocol Serializable {
    func serialize() -> Any
}

public extension Serializable {
    public func serialize() -> Any {
        return Kakapo.serialize(self)
    }
}

extension Array: Serializable {
    public func serialize() -> Any {
        var array = [Any]()
        for obj in self {
            array.append(serializeObject(obj))
        }
        return array
    }
}

extension Dictionary: Serializable {
    public func serialize() -> Any {
        var dictionary = [Key: Any]()
        for (key, value) in self {
            dictionary[key] = serializeObject(value)
        }
        return dictionary
    }
}

extension Optional: Serializable {
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
    private func flatten(obj: Any) -> Any {
        if obj is _PropertyPolicy {
            return flatten(obj)// recursive in case it contains a property policy
        }
        return obj
    }
    
    public func serialize() -> Any {
        return serializeObject(flatten(_object))
    }
}

private func serializeObject(value: Any) -> Any {
    if let value = value as? Serializable {
        return value.serialize()
    } else {
        assert(value is AnyObject) // TODO: throw
        return value
    }
}

public func serialize(object: Serializable) -> [String: Any] {
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
