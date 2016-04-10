//
//  JSONRepresentation.swift
//  KakapoExample
//
//  Created by Alex Manzella on 09/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

public protocol JSONAPIEntity: Serializable {
    var id: Int { get }
    var type: String { get }
}

extension JSONAPIEntity {
    public var type: String {
        get {
            return String(self.self).lowercaseString
        }
    }
}

public struct JSONAPIRepresentation<T: JSONAPIEntity>: Serializable, CustomReflectable, CustomStringConvertible {

    private let object: T
    
    public var description: String {
        get {
            return (self.serialize() as! [String: Any]).description
        }
    }
    
    public init(_ object: T) {
        self.object = object
    }
    
    // TODO: make it hackable
    public func customMirror() -> Mirror {
        var children = [(label: String?, value: Any)]()
        
        func append(label: String?, value: Any) {
            children.append((label: label, value: value))
        }

        // data
        var data = [[String: Any]]()
        data.append(["type": object.type, "id": object.id])
        append("data", value: data)

        // included
        var included = [[String: Any]]()
        included.append(["type": object.type, "id": object.id])
        append("data", value: data)

        append("included", value: data)

        return Mirror(self, children: AnyForwardCollection(children))
    }
}
