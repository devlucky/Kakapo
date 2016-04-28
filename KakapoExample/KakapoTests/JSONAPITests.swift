//
//  JSONAPITests.swift
//  KakapoExample
//
//  Created by Alex Manzella on 28/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Kakapo

class JSONAPISpec: QuickSpec {
    
    struct User: JSONAPIEntity {
        let name: String
    }
    
    override func spec() {
        let user = User(name: "Alex")
        
        describe("JSON API serialization") {
            it("....") {
                let serialized = JSONAPISerializer(user)
            }
            
            it("......") {
                let serialized = JSONAPISerializer([user])
            }
        }
    }
}