//
//  XCTestCase+ProgrammerAssertions.swift
//  Assertions
//
//  Created by Mohamed Afifi on 12/20/15.
//  Copyright © 2015 mohamede1945. All rights reserved.
//

/// ### IMPORTANT HOW TO USE ###
/// 1. Drop `ProgrammerAssertions.swift` to the target of your app or framework under test. Just besides your source code.
/// 2. Drop `XCTestCase+ProgrammerAssertions.swift` to your test target. Just besides your test cases.
/// 3. Use `assert`, `assertionFailure`, `precondition`, `preconditionFailure` and `fatalError` normally as you always do.
/// 4. Unit test them with the new methods `expectAssert`, `expectAssertionFailure`, `expectPrecondition`, `expectPreconditionFailure` and `expectFatalError`.
///
/// This file is the unit test assertions.
/// For a complete project example see <https://github.com/mohamede1945/AssertionsTestingExample>

import Foundation
import XCTest
import Quick
import Nimble
@testable import Kakapo

private let noReturnFailureWaitTime = 0.1

public extension XCTestCase {
    
    /**
     Expects an `assert` to be called with a false condition.
     If `assert` not called or the assert's condition is true, the test case will fail.
     
     - parameter expectedMessage: The expected message to be asserted to the one passed to the `assert`. If nil, then ignored.
     - parameter file:            The file name that called the method.
     - parameter line:            The line number that called the method.
     - parameter testCase:        The test case to be executed that expected to fire the assertion method.
     */
    public func expectAssert(
        expectedMessage: String? = nil,
        file: StaticString = #file,
        line: UInt = #line,
        testCase: () -> Void
        ) {
        
        expectAssertionReturnFunction("assert", file: file, line: line, function: { (caller) -> () in
            
            Assertions.assertClosure = { condition, message, _, _ in
                caller(condition, message)
            }
            
        }, expectedMessage: expectedMessage, testCase: testCase) { () -> () in
            Assertions.assertClosure = Assertions.swiftAssertClosure
        }
    }
    
    /**
     Expects an `assertionFailure` to be called.
     If `assertionFailure` not called, the test case will fail.
     
     - parameter expectedMessage: The expected message to be asserted to the one passed to the `assertionFailure`. If nil, then ignored.
     - parameter file:            The file name that called the method.
     - parameter line:            The line number that called the method.
     - parameter testCase:        The test case to be executed that expected to fire the assertion method.
     */
    public func expectAssertionFailure(
        expectedMessage: String? = nil,
        file: StaticString = #file,
        line: UInt = #line,
        testCase: () -> Void
        ) {
        
        expectAssertionReturnFunction("assertionFailure", file: file, line: line, function: { (caller) -> () in
            
            Assertions.assertionFailureClosure = { message, _, _ in
                caller(false, message)
            }
            
        }, expectedMessage: expectedMessage, testCase: testCase) { () -> () in
            Assertions.assertionFailureClosure = Assertions.swiftAssertionFailureClosure
        }
    }
    
    /**
     Expects an `precondition` to be called with a false condition.
     If `precondition` not called or the precondition's condition is true, the test case will fail.
     
     - parameter expectedMessage: The expected message to be asserted to the one passed to the `precondition`. If nil, then ignored.
     - parameter file:            The file name that called the method.
     - parameter line:            The line number that called the method.
     - parameter testCase:        The test case to be executed that expected to fire the assertion method.
     */
    public func expectPrecondition(
        expectedMessage: String? = nil,
        file: StaticString = #file,
        line: UInt = #line,
        testCase: () -> Void
        ) {
        
        expectAssertionReturnFunction("precondition", file: file, line: line, function: { (caller) -> () in
            
            Assertions.preconditionClosure = { condition, message, _, _ in
                caller(condition, message)
            }
            
        }, expectedMessage: expectedMessage, testCase: testCase) { () -> () in
            Assertions.preconditionClosure = Assertions.swiftPreconditionClosure
        }
    }
    
    /**
     Expects an `preconditionFailure` to be called.
     If `preconditionFailure` not called, the test case will fail.
     
     - parameter expectedMessage: The expected message to be asserted to the one passed to the `preconditionFailure`. If nil, then ignored.
     - parameter file:            The file name that called the method.
     - parameter line:            The line number that called the method.
     - parameter testCase:        The test case to be executed that expected to fire the assertion method.
     */
    public func expectPreconditionFailure(
        expectedMessage: String? = nil,
        file: StaticString = #file,
        line: UInt = #line,
        testCase: () -> Void
        ) {
        
        expectAssertionNoReturnFunction("preconditionFailure", file: file, line: line, function: { (caller) -> () in
            
            Assertions.preconditionFailureClosure = { message, _, _ in
                caller(message)
            }
            
        }, expectedMessage: expectedMessage, testCase: testCase) { () -> () in
            Assertions.preconditionFailureClosure = Assertions.swiftPreconditionFailureClosure
        }
    }
    
    /**
     Expects an `fatalError` to be called.
     If `fatalError` not called, the test case will fail.
     
     - parameter expectedMessage: The expected message to be asserted to the one passed to the `fatalError`. If nil, then ignored.
     - parameter file:            The file name that called the method.
     - parameter line:            The line number that called the method.
     - parameter testCase:        The test case to be executed that expected to fire the assertion method.
     */
    public func expectFatalError(
        expectedMessage: String? = nil,
        file: StaticString = #file,
        line: UInt = #line,
        testCase: () -> Void) {
        
        expectAssertionNoReturnFunction("fatalError", file: file, line: line, function: { (caller) -> () in
            
            Assertions.fatalErrorClosure = { message, _, _ in
                caller(message)
            }
            
        }, expectedMessage: expectedMessage, testCase: testCase) { () -> () in
            Assertions.fatalErrorClosure = Assertions.swiftFatalErrorClosure
        }
    }
    
    // MARK:- Private Methods
    
    private func expectAssertionReturnFunction(
        functionName: String,
        file: StaticString,
        line: UInt,
        function: (caller: (Bool, String) -> Void) -> Void,
        expectedMessage: String? = nil,
        testCase: () -> Void,
        cleanUp: () -> ()
        ) {
        
        var message: String? = nil
        
        function { (condition, mes) -> Void in
            expect(condition).to(beFalse())
            message = mes
        }
        
        // perform on the same thread since it will return
        testCase()
        
        defer {
            // clean up
            cleanUp()
        }
            
        expect(message).toEventually(equal(expectedMessage))
    }
    
    private func expectAssertionNoReturnFunction(
        functionName: String,
        file: StaticString,
        line: UInt,
        function: (caller: (String) -> Void) -> Void,
        expectedMessage: String? = nil,
        testCase: () -> Void,
        cleanUp: () -> ()
        ) {
        
        var assertionMessage: String? = nil
        
        function { (message) -> Void in
            assertionMessage = message
        }
        
        // act, perform on separate thead because a call to function runs forever
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), testCase)
        
        defer {
            // clean up
            cleanUp()
        }
        
        expect(assertionMessage).toEventually(be(expectedMessage))
    }
}
