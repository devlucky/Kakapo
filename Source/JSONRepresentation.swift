//
//  JSONRepresentation.swift
//  KakapoExample
//
//  Created by Alex Manzella on 09/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 *  The entry point for serialization. The object will be Mirrored and its children serialized (Use CustomReflectable conformance for complex structures). You can create a concrete type that holds Serializable Objects.
 
   Example:
    ```
        JSONAPIRepresentation(User(name: ".."))
    ```
 */
protocol JSONRepresentation: Serializable {
    func toJSON() -> String
}

extension JSONRepresentation {
    func toJSON() -> String {
        return "\(self)" // TODO: real serialization
    }
}

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

public struct JSONAPIRepresentation<T: JSONAPIEntity>: JSONRepresentation, CustomReflectable, CustomStringConvertible {

    private let object: T
    
    public var description: String {
        get {
            return Kakapo.serialize(self).description
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
