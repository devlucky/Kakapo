//
//  JSONAPIError.swift
//  Kakapo
//
//  Created by Alex Manzella on 26/06/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

// A convenince error object that conform to JSON API
public struct JSONAPIError: ResponseFieldsProvider {
    
    /// A builder for JSONAPIError
    public struct JSONAPIErrorBuilder: Serializable {
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
        public var source: String?
        
        /// A meta object containing non-standard meta-information about the error.
        public var meta: Serializable?
        
        private init(statusCode: Int) {
            status = statusCode
        }
    }
    
    private let builder: JSONAPIErrorBuilder

    // MARK: ResponseFieldsProvider
    
    public var statusCode: Int {
        return builder.status
    }
    
    public var body: Serializable {
        return builder
    }
    
    public var headerFields: [String : String]? {
        return nil
    }

    /**
     Initialize a `JSONAPIError` and build it with `JSONAPIErrorBuilder`
     
     - parameter statusCode:   the status code of the response, will be used also to provide a statusCode for your request
     - parameter errorBuilder: A builder that can be used to fill the error objects, it contains all you need to provide an error object confiorming to JSON API (**see `JSONAPIErrorBuilder`**)
     
     - returns: An error that conforms to JSON API specifications and it's ready to be serialized
     */
    public init(statusCode: Int, errorBuilder: (error: inout JSONAPIErrorBuilder) -> ()) {
        var builder = JSONAPIErrorBuilder(statusCode: statusCode)
        errorBuilder(error: &builder)
        self.builder = builder
    }
    
}