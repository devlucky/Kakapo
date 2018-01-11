//
//  StorePerformanceTests.swift
//  Kakapo
//
//  Copyright © 2018 devlucky. All rights reserved.
//

import XCTest

@testable import Kakapo

class StorePerformaceTests: XCTestCase {

    func testMultipleSingleCreationPerformance() {
        let sut = Store()
        measure {
            DispatchQueue.concurrentPerform(iterations: 1000) { _ in
                sut.create(User.self)
            }
        }
    }

    func testMultpleInsertionsPerformance() {
        let sut = Store()
        measure {
            DispatchQueue.concurrentPerform(iterations: 1000) { _ in
                sut.insert { (id) -> User in
                    return User(id: id, store: sut)
                }
            }
        }
    }

    func testMultipleDeletionsPerformance() {
        let sut = Store()
        sut.create(User.self, number: 2000)
        measure {
            for entity in sut.findAll(User.self) {
                try! sut.delete(entity)
            }
        }
    }
}
