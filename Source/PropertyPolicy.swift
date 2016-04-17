//
//  PropertyPolicy.swift
//  KakapoExample
//
//  Created by Alex Manzella on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 *  A *"type-erased"* protocol that should only be used internally as constraint for `PropertyPolicy` (concrete protocol with associatedtype). **See `PropertyPolicy`**
 */
public protocol _PropertyPolicy: CustomSerializable {
    var _object: Any { get }
    var shouldSerialize: Bool { get }
}

/**
 *  `PropertyPolicy` is a Simple serializable object that can be used to wrap your `Serializable` Objects' properties to add specific behaviors to the property. Concrete implementation can manipulate the object hold by the property policy to achieve specific results. **See `IgnorableNilProperty`**
 */
public protocol PropertyPolicy: _PropertyPolicy {
    associatedtype T
    
    /// The object that will be serialized when shouldSerialize return true. Use specific type or Any for multiple types. Make sure it's an elegible `Serializable` or Property list object. **See `Serializable`**
    var object: T? { get }
    // Indicated if the property should be serialized or ignored
    var shouldSerialize: Bool { get }
}

extension PropertyPolicy {
    // Fake type erasure in _PropertyPolicy
    public var _object: Any {
        get {
            return object
        }
    }
}

/**
 *  A `PropertyPolicy` that ignores nil value for optional properties. By default nil is converted to `NSNull`; wrap your property into this policy to avoid this.
 
 ```
    let myNilIgnorableProperty: IgnorableNilProperty<Int>
 ```
 
 serializes the object when not nil and ignores it when nil.
 */
public struct IgnorableNilProperty<T>: PropertyPolicy {
    public let object: T?
    
    init(_ object: T?) {
        self.object = object
    }
    
    public var shouldSerialize: Bool {
        return object != nil
    }
}
