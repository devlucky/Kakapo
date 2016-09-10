//
//  PropertyPolicyTests.swift
//  Kakapo
//
//  Created by Alex Manzella on 29/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Kakapo

private struct Test<T>: Serializable {
    let value: PropertyPolicy<T>
}

private struct Person: Serializable {
    let name: String
}

class IgnorableNilPropertySpec: QuickSpec {    

    override func spec() {
        
        describe("Property policy serialization") {
            it("is not serialized if nil") {
                let serialized = Test(value: PropertyPolicy<Int>.none).serialize() as! [String: AnyObject]
                expect(serialized.count).to(be(0))
            }
            
            it("is serialized if not nil") {
                let serialized = Test(value: PropertyPolicy.some(1)).serialize() as! [String: AnyObject]
                expect(serialized.count).to(be(1))
                let value = serialized["value"] as? Int
                expect(value).to(be(1))
            }
            
            it("return NSNull when .Null") {
                let serialized = Test(value: PropertyPolicy<Int>.null).serialize() as! [String: AnyObject]
                expect(serialized.count).to(be(1))
                let value = serialized["value"] as? NSNull
                expect(value).toNot(beNil())
            }
            
            it("recursively serialize the object if needed") {
                let serialized = Test(value: PropertyPolicy.some(Person(name: "Alex"))).serialize() as! [String: AnyObject]
                expect(serialized.count).to(be(1))
                let value = serialized["value"] as? [String: AnyObject]
                expect(value?["name"] as? String).to(equal("Alex"))
            }
            
            it("recursively serialize PropertyPolicy") {
                let policy = PropertyPolicy.some(1)
                let policyOfPolicy = PropertyPolicy.some(policy)
                let serialized = Test(value: policyOfPolicy).serialize() as! [String: AnyObject]
                expect(serialized.count).to(be(1))
                let value = serialized["value"] as? Int
                expect(value).to(be(1))
            }
        }
    }
}
