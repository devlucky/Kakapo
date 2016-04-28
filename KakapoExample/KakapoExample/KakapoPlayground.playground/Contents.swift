//: Playground - noun: a place where people can play

import UIKit
@testable import Kakapo

struct Dog: JSONAPIEntity {
    let id: Int
    let name: String
}

struct Friend: JSONAPIEntity {
    let id: Int
    let name: String
    let dog: Dog
}

struct User: JSONAPIEntity {
    let id: Int
    let name: String
    let friend: [Friend]
}

func pprint(obj: AnyObject) {
    let data = try! NSJSONSerialization.dataWithJSONObject(obj, options: .PrettyPrinted)
    print(NSString(data: data, encoding: 0)!)
}

pprint(JSONAPISerializer(User(id: 1, name: "s", friend: [Friend(id: 33, name: "a", dog: Dog(id: 134, name: "Zarco"))])).serialize())

//pprint(JSONAPISerializer([Friend(id: 33, name: "a")]).serialize())
