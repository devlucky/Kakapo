//
//  JSONAPISerialization.swift
//  KakapoExample
//
//  Created by Alex Manzella on 28/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

protocol JSONAPIConvertible {
    func data() -> [String: AnyObject]
}

protocol JSONAPIEntity: Serializable, JSONAPIConvertible {
    var type: String { get }
    var id: Int { get }
}

extension JSONAPIEntity {
    var type: String {
        return String(self).lowercaseString
    }
}

extension Array where Element: JSONAPIEntity {
    func data() -> [String: AnyObject] {
        return [String: AnyObject]()
    }
}

extension JSONAPIConvertible {
    func data() -> [String: AnyObject] {
        return [String: AnyObject]()
    }
}

struct JSONAPISerializer<T: JSONAPIEntity>: CustomSerializable {
    
    let data: [String: AnyObject]
    
    init(_ object: T) {
        data = object.data()
    }
    
    init(_ objects: [T]) {
        data = objects.data()
    }
    
    func customSerialize() -> AnyObject {
        return ["data": data]
    }
}