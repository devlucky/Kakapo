//
//  KakapoServerTests.swift
//  KakapoExample
//
//  Created by Joan Romano on 02/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

import Quick
import Nimble

@testable import Kakapo

class KakapoServerTests: QuickSpec {
    
    override func spec() {
        var db = KakapoDB()
        
        beforeEach{
            db = KakapoDB()
            KakapoServer.enable()
        }
        
        afterEach{
            KakapoServer.disable()
        }
        
        describe("Registering urls") {
            
            it("should call the handler when requesting a registered url") {
                var info: URLInfo? = nil
                var responseURL: NSURL? = nil
                
                KakapoServer.get("/users/:id"){ request in
                    info = request.info
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "/users/1")!) { (data, response, _) in
                    responseURL = response?.URL
                }.resume()
                
                expect(info?.params).toEventually(equal(["id" : "1"]))
                expect(info?.queryParams).toEventually(equal([ : ]))
                expect(responseURL?.absoluteString).toEventually(equal("/users/1"))
            }
            
            it("should call the handler when requesting multiple registered urls") {
                var usersInfo: URLInfo? = nil
                var usersResponseURL: NSURL? = nil
                var usersCommentsInfo: URLInfo? = nil
                var usersCommentsResponseURL: NSURL? = nil
                
                KakapoServer.get("/comments/:id") { request in
                    XCTFail("Shouldn't reach here")
                    usersInfo = request.info
                    return nil
                }
                
                KakapoServer.get("/users/:id") { request in
                    usersInfo = request.info
                    return nil
                }
                
                KakapoServer.get("/commentaries/:id") { request in
                    XCTFail("Shouldn't reach here")
                    usersInfo = request.info
                    return nil
                }
                
                KakapoServer.get("/users/:id/comments/:comment_id") { request in
                    usersCommentsInfo = request.info
                    return nil
                }
                
                KakapoServer.get("/users/:id/comments/:comment_id/whatever") { request in
                    XCTFail("Shouldn't reach here")
                    usersCommentsInfo = request.info
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "/users/1")!) { (_, response, _) in
                    usersResponseURL = response?.URL
                }.resume()
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "/users/1/comments/2?page=2&author=hector")!) { (_, response, _) in
                    usersCommentsResponseURL = response?.URL
                }.resume()
                
                expect(usersInfo?.params).toEventually(equal(["id" : "1"]))
                expect(usersInfo?.queryParams).toEventually(equal([ : ]))
                expect(usersResponseURL?.absoluteString).toEventually(equal("/users/1"))
                expect(usersCommentsInfo?.params).toEventually(equal(["id": "1", "comment_id": "2"]))
                expect(usersCommentsInfo?.queryParams).toEventually(equal(["page": "2", "author": "hector"]))
                expect(usersCommentsResponseURL?.absoluteString).toEventually(equal("/users/1/comments/2?page=2&author=hector"))
            }
        }
        
        describe("Non registered urls") {
            it("should not call the handler when requesting a non registered url") {
                var info: URLInfo? = nil
                var responseURL: NSURL? = NSURL(string: "")
                var responseError: NSError? = NSError(domain: "", code: 1, userInfo: nil)
                
                KakapoServer.get("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    info = request.info
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "/userssssss/1")!) { (_, response, error) in
                    // Response will be nil since error
                    responseURL = response?.URL
                    responseError = error
                    }.resume()
                
                expect(info?.params).toEventually(beNil())
                expect(info?.queryParams).toEventually(beNil())
                expect(responseURL?.absoluteString).toEventually(beNil())
                expect(responseError).toNotEventually(beNil())
            }
            
            it("should not call the handler when requesting a registered url but using a different HTTPMethod") {
                var info: URLInfo? = nil
                var responseURL: NSURL? = NSURL(string: "")
                var responseError: NSError? = NSError(domain: "", code: 1, userInfo: nil)
                
                KakapoServer.del("/users/:id") { request in
                    XCTFail("Shouldn't reach here")
                    info = request.info
                    return nil
                }
                
                let request = NSMutableURLRequest(URL: NSURL(string: "/users/1")!)
                request.HTTPMethod = "PUT"
                NSURLSession.sharedSession().dataTaskWithRequest(request) { (_, response, error) in
                    // Response will be nil since error
                    responseURL = response?.URL
                    responseError = error
                    }.resume()
                
                expect(info).toEventually(beNil())
                expect(responseURL).toEventually(beNil())
                expect(responseError).toNotEventually(beNil())
            }
        }
        
        describe("Request body") {
            it("should give back the body in the handler when a NSURLSession request has it") {
                var info: URLInfo? = nil
                var bodyData: NSData? = nil
                var bodyDictionary: NSDictionary? = nil
                
                let request = NSMutableURLRequest(URL: NSURL(string: "/users/1")!)
                request.HTTPMethod = "POST"
                let params = ["username":"test", "password":"pass"] as Dictionary<String, String>
                request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(params, options: .PrettyPrinted)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                KakapoServer.post("/users/:id") { request in
                    info = request.info
                    bodyData = request.HTTPBody
                    bodyDictionary = try! NSJSONSerialization.JSONObjectWithData(bodyData!, options: .MutableLeaves) as? NSDictionary
                    
                    return nil
                }
                
                NSURLSession.sharedSession().dataTaskWithRequest(request){ (_, _, _) in }.resume()
                
                expect(info?.params).toEventually(equal(["id" : "1"]))
                expect(info?.queryParams).toEventually(equal([ : ]))
                expect(bodyData).toNotEventually(beNil())
                expect(bodyDictionary!["username"] as? String).toEventually(equal("test"))
                expect(bodyDictionary!["password"] as? String).toEventually(equal("pass"))
            }
            
            it("should give back the body in the handler when a NSURLConnection request has is") {
                var info: URLInfo? = nil
                var bodyData: NSData? = nil
                var bodyDictionary: NSDictionary? = nil
                
                let request = NSMutableURLRequest(URL: NSURL(string: "/user_equipment/1")!)
                request.HTTPMethod = "PUT"
                let params = ["username":"manzo", "token":"power"] as Dictionary<String, String>
                request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(params, options: .PrettyPrinted)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                KakapoServer.put("/user_equipment/:id") { request in
                    info = request.info
                    bodyData = request.HTTPBody
                    bodyDictionary = try! NSJSONSerialization.JSONObjectWithData(bodyData!, options: .MutableLeaves) as? NSDictionary
                    
                    return nil
                }
                
                let _ = NSURLConnection(request: request, delegate: nil)
                
                expect(info?.params).toEventually(equal(["id" : "1"]))
                expect(info?.queryParams).toEventually(equal([ : ]))
                expect(bodyData).toNotEventually(beNil())
                expect(bodyDictionary!["username"] as? String).toEventually(equal("manzo"))
                expect(bodyDictionary!["token"] as? String).toEventually(equal("power"))
            }
        }
        
        describe("Response objects") {
            it("should return the specified object when requesting a registered url") {
                db.create(UserFactory.self, number: 20)
                
                var responseDictionary: NSDictionary? = nil
                
                KakapoServer.get("/users/:id"){ request in
                    return db.find(UserFactory.self, id: Int(request.info.params["id"]!)!)
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "/users/2")!) { (data, response, _) in
                    responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
                    }.resume()
                
                expect(responseDictionary?["firstName"]).toNotEventually(beNil())
                expect(responseDictionary?["id"]).toEventually(be(2))
            }
            
            it("should return the specified array of objects when requesting a registered url") {
                db.create(UserFactory.self, number: 20)
                
                var responseArray: NSArray? = nil
                
                KakapoServer.get("/users"){ request in
                    return db.findAll(UserFactory)
                }
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "/users")!) { (data, response, _) in
                    responseArray = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSArray
                    }.resume()
                
                expect(responseArray?.count).toEventually(equal(20))
                expect(responseArray?.firstObject?["firstName"]).toNotEventually(beNil())
                expect(responseArray?.firstObject?["id"]).toEventually(equal(0))
                expect(responseArray?[14]["id"]).toEventually(equal(14))
                expect(responseArray?.lastObject?["id"]).toEventually(equal(19))
            }
            
            it("should return nil for objects not serializable to JSON") {
                KakapoServer.get("/nothing/:id"){ request in
                    return Optional.Some("none")
                }
                
                var called = false
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "/nothing/1")!) { (data, response, _) in
                    called = true
                    expect(data?.length).to(equal(0))
                }.resume()
                
                expect(called).toEventually(beTrue())
            }
        }
    }
}