//
//  PropertyPolicy.swift
//  Kakapo
//
//  Created by Alex Manzella on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 `PropertyPolicy` is an enum similar to `Optional` but with an additional case `.null`. It's only purpose is to be serialized in 3 different ways to cover all possible behaviors of an Optional property.
 
 - None:     Same behavior of `Optional.none`, the property is not included in the JSON
 - Null:     `Null` when serialized is `NSNull` that will result as a `null` property in the JSON
 - Some:     Serialize the associated object
 */
public enum PropertyPolicy<Wrapped>: CustomSerializable {
    /// Same behavior of `Optional.none`, the property is not included in the JSON
    case none
    /// `null` when serialized is `NSNull` that will result as a `null` property in the JSON
    case null
    /// Serialize the associated object
    case some(Wrapped)
}
