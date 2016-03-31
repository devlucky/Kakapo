//
//  PropertyPolicy.swift
//  KakapoExample
//
//  Created by Alex Manzella on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

public protocol PropertyPolicy: CustomReflectable {
    var shouldSerialize: Bool { get }
}

public struct KakapoIgnorableNilProperty<T>: PropertyPolicy {
    let obj: T?
    
    public var shouldSerialize: Bool {
        return obj != nil
    }
    
    public func customMirror() -> Mirror {
        return Mirror(reflecting: obj)
    }
}
