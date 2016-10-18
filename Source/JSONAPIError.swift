//
//  JSONAPIError.swift
//  Kakapo
//
//  Created by Alex Manzella on 08/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/// A convenience error object that conform to JSON API
public struct JSONAPIError: ResponseFieldsProvider {
    
    /// An object containing references to the source of the error, optionally including any of the following members
    public struct Source: Serializable {
        /// A JSON `Pointer` ([RFC6901](https://tools.ietf.org/html/rfc6901)) to the associated entity in the request document [e.g. `/data` for a primary data object, or `/data/attributes/title` for a specific attribute].
        public let pointer: String?
        
        /// A string indicating which URI query parameter caused the error.
        public let parameter: String?
        
        /**
         Initialize `Source` with the given parameters
         
         - parameter pointer:   A JSON `Pointer` ([RFC6901](https://tools.ietf.org/html/rfc6901)) to the associated entity in the request document [e.g. `/data` for a primary data object, or `/data/attributes/title` for a specific attribute].
         - parameter parameter: A string indicating which URI query parameter caused the error.
         
         - returns: An initialized `Source` representing the source of the `JSONAPIError`.
         */
        public init(pointer: String?, parameter: String?) {
            self.pointer = pointer
            self.parameter = parameter
        }
    }
    
    /// A builder for JSONAPIError
    public class Builder: Serializable {
        
        /// A unique identifier for this particular occurrence of the problem.
        public var id: String?
        
        /// A link object that leads to further details about this particular occurrence of the problem.
        public var about: JSONAPILink?
        
        /// The HTTP status code applicable to this problem, expressed as a string value.
        public var status: Int
        
        /// An application-specific error code, expressed as a string value
        public var code: String?
        
        /// A short, human-readable summary of the problem that SHOULD NOT change from occurrence to occurrence of the problem, except for purposes of localization
        public var title: String?
        
        /// A human-readable explanation specific to this occurrence of the problem. Like title, this field’s value can be localized.
        public var detail: String?
        
        /**
         An object containing references to the source of the error, optionally including any of the following members:
         
         - pointer: a JSON `Pointer` ([RFC6901](https://tools.ietf.org/html/rfc6901)) to the associated entity in the request document [e.g. `/data` for a primary data object, or `/data/attributes/title` for a specific attribute].
         - parameter: a string indicating which URI query parameter caused the error.
         */
        public var source: Source?
        
        /// A meta object containing non-standard meta-information about the error.
        public var meta: Serializable?
        
        fileprivate init(statusCode: Int) {
            status = statusCode
        }
    }
    
    private let builder: Builder

    // MARK: ResponseFieldsProvider
    
    /// The status code that will be used to affect the HTTP request status code.
    public var statusCode: Int {
        return builder.status
    }
    
    /// A `JSONAPIError.Builder` instance contains all the fields.
    public var body: Serializable {
        return builder
    }
    
    /// The headerFields that will be returned by the HTTP response.
    public let headerFields: [String : String]?

    /**
     Initialize a `JSONAPIError` and build it with `JSONAPIError.Builder`
     
     - parameter statusCode:   The status code of the response, will be used also to provide a statusCode for your request
     - parameter headerFields: The headerFields that will be returned by the HTTP response.
     - parameter errorBuilder: A builder that can be used to fill the error objects, it contains all you need to provide an error object confiorming to JSON API (**see `JSONAPIError.Builder`**)
     
     - returns: An error that conforms to JSON API specifications and it's ready to be serialized
     */
    public init(statusCode: Int, headerFields: [String: String]? = nil, errorBuilder: (_ error: Builder) -> ()) {
        let builder = Builder(statusCode: statusCode)
        errorBuilder(builder)
        self.builder = builder
        self.headerFields = headerFields
    }
    
}
