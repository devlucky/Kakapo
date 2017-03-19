//
//  ResponseFieldsProvider.swift
//  Kakapo
//
//  Created by Alex Manzella on 19/03/17.
//  Copyright © 2017 devlucky. All rights reserved.
//

import Foundation

/**
 A protocol to adopt when a `Serializable object needs to also provide response status code and/or headerFields
 For example you may use `Response` to wrap your `Serializable` object to just achieve the result or directly implement the protocol.
 For example `JSONAPIError` implement the protocol in order to be able to provide custom status code in the response.
 */
public protocol ResponseFieldsProvider {
    /// The response status code
    var statusCode: Int { get }

    /// The Serializable body object
    var body: Data? { get }

    /// An optional dictionary holding the response header fields
    var headerFields: [String : String]? { get }
}
