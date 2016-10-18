//
//  SerializationTransformer.swift
//  Kakapo
//
//  Created by Alex Manzella on 27/06/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/// A closure that given a String as input output the transformed String, used to transform keys of the json
public typealias KeyTransformer = (_ key: String) -> String

/**
 *  A protocol that special `Serializable` objects can adopt to transform other **wrapped** `Serializable` objects.
 *  At the moment this protocol only provide the key transformation functionality.
 *  See `SnakecaseTransformer` for a concrete implementation.
 */
public protocol SerializationTransformer: CustomSerializable {
    
    /// The wrapped object type
    associatedtype Wrapped: Serializable
    
    /// The wrapped `Serializable` object
    var wrapped: Wrapped { get }
    
    /**
     A function that given a String as input output the transformed String, used to transform keys of the json
     
     - parameter key: The key to transform
     
     - returns: Should return the transformed key, for example an `UppercaseTransformer` would return the uppercase key.
     */
    func transform(key: String) -> String
}

extension SerializationTransformer {
    
    /**
     `SerializationTransformer` by default serialize it's object using the given keyTransformer (if any) and it's own key transformer.
     Its own keyTransformer must always be used before the one provided by the callers, so UppercaseTransformer(LowercaseTransformer(object)) would result in uppercase keys.
     
     - returns: The serialized wrapped object with transformed keys.
     */
    public func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        return wrapped.serialized { (string) in
            let transformed = self.transform(key: string)
            return keyTransformer?(transformed) ?? transformed
        }
    }
}

/**
 *  A `SerializableTransformer` that transform `camelCase` json keys in `snake_case` keys.
 
    Example:
    ```
    struct User {
       let userName: String
    }
 
    let result = SnakecaseTransformer(wrapped: User(userName: "Alex")) // -> {"user_name": "Alex"}
 
    ```
 */
public struct SnakecaseTransformer<Wrapped: Serializable>: SerializationTransformer {
    
    /// The wrapped `Serializable` object
    public let wrapped: Wrapped
    
    /**
     Initialize a `SnakecaseTransformer` wrapping a `Serializable` object to transform its keys during serialization.
     
     - parameter wrapped: A wrapped `Serializable` object
     
     - returns: A `Serializable` object that will transform the keys of the wrapped object when serialized.
     */
    public init(_ wrapped: Wrapped) {
        self.wrapped = wrapped
    }
    
    /**
     Transform the input string from `camelCase` to `snake_case`
     
     - parameter key: A `camelCase` string
     
     - returns: The input key transformed to `snake_case`
     */
    public func transform(key: String) -> String {
        return key.snakecaseString()
    }
}

private extension String {
    
    /// Converts a camelCase string into a snake_case one.
    func snakecaseString() -> String {
        var string = String()
        let charactersView = self.characters
        let startIndex = charactersView.startIndex
        let endIndex = charactersView.count - 1
        
        for (idx, c) in charactersView.reversed().enumerated() {
            let char = String(c)
            let lowerCased = char.lowercased()
            let isUppercase = char != lowerCased
            
            string.insert(Character(lowerCased), at: startIndex)
            
            if isUppercase && idx != endIndex {
                string.insert("_", at: startIndex)
            }
        }
        return string
    }
}
