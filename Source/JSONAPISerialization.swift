//
//  JSONAPISerialization.swift
//  KakapoExample
//
//  Created by Alex Manzella on 28/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

public protocol JSONAPISerializable {
    func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool) -> AnyObject?
}

public protocol JSONAPIEntity: CustomSerializable, JSONAPISerializable {
    var type: String { get }
    var id: Int { get }
}

extension Array: JSONAPISerializable {
    public func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool) -> AnyObject? {
        let data = flatMap { ($0 as? JSONAPISerializable)?.data(includeRelationships: includeRelationships, includeAttributes: includeAttributes) }
        return data.count > 0 ? data : nil
    }
}

public extension JSONAPIEntity {
    var type: String {
        return String(self.dynamicType).lowercaseString
    }
    
    public func customSerialize() -> AnyObject {
        return data(includeRelationships: true, includeAttributes: true)!
    }
    
    public func data(includeRelationships includeRelationships: Bool, includeAttributes: Bool) -> AnyObject? {
        var data = [String: AnyObject]()
        
        data["id"] = String(id)
        data["type"] = type
        
        let mirror = Mirror(reflecting: self)
        
        var attributes = [String: AnyObject]()
        var relationships = [String: AnyObject]()
        
        for child in mirror.children {
            if let label = child.label {
                if child.value is _PropertyPolicy {
                    
                } else if let value = child.value as? JSONAPISerializable, let data = value.data(includeRelationships: false, includeAttributes: false) {
                    relationships[label] =  ["data": data]
                } else if let value = child.value as? Serializable {
                    attributes[label] = value.serialize()
                } else {
                    assert(child.value is AnyObject)
                    attributes[label] = child.value as? AnyObject
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
}

struct JSONAPISerializer<T: JSONAPIEntity>: CustomSerializable {
    
    let data: AnyObject
    
    init(_ object: T) {
        data = object.serialize()
    }
    
    init(_ objects: [T]) {
        data = objects.serialize()
    }
    
    func customSerialize() -> AnyObject {
        return ["data": data]
    }
}