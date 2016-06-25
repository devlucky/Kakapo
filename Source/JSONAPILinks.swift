//
//  JSONAPILinks.swift
//  Kakapo
//
//  Created by Joan Romano on 19/06/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

public enum JSONAPILink: CustomSerializable {
    case Simple(value: String)
    case Object(href: String, meta: Serializable)
    
    public func customSerialize() -> AnyObject? {
        switch self {
        case let Object(href, meta):
            var serializedObject = [String: AnyObject](dictionaryLiteral: ("href", href))
            serializedObject["meta"] = meta.serialize()
            
            return serializedObject
        case let Simple(value):
            return value
        }
    }
}

public protocol JSONAPILinkedEntity {
    var links: [String : JSONAPILink]? { get }
    var topLinks: [String : JSONAPILink]? { get }
}

extension JSONAPILinkedEntity {
    public var links: [String : JSONAPILink]? { return nil }
    public var topLinks: [String : JSONAPILink]? { return nil }
}

extension Array: JSONAPILinkedEntity {
    public var topLinks: [String : JSONAPILink]? {
        var returnLinks = [String : JSONAPILink]()
        
        for linkedEntity in self {
            guard let linkedEntity = linkedEntity as? JSONAPILinkedEntity,
                      links = linkedEntity.topLinks else { break }
            returnLinks += links
        }
        
        return !returnLinks.isEmpty ? returnLinks : nil
    }
}

private func += <K, V> (inout left: [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}
