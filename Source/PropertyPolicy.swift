//
//  PropertyPolicy.swift
//  KakapoExample
//
//  Created by Alex Manzella on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

public protocol _PropertyPolicy: Serializable {
    var _object: Any { get }
    var shouldSerialize: Bool { get }
}

public protocol PropertyPolicy: _PropertyPolicy {
    typealias T
    var object: T? { get }
    var shouldSerialize: Bool { get }
}

extension PropertyPolicy {
    public var _object: Any {
        get {
            return object
        }
    }
}

public struct IgnorableNilProperty<T>: PropertyPolicy {
    public let object: T?
    
    init(_ object: T?) {
        self.object = object
    }
    
    public var shouldSerialize: Bool {
        return object != nil
    }
}
