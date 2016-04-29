//: Playground - noun: a place where people can play

import UIKit
import Kakapo

struct Dog: JSONAPIEntity {
    let id: String
    let name: String
}

struct Friend: JSONAPIEntity {
    let id: String
    let name: String
    let dog: Dog
}

struct User: JSONAPIEntity {
    let id: String
    let name: String
    let friend: [Friend]
}

func pprint(obj: AnyObject) {
    let data = try! NSJSONSerialization.dataWithJSONObject(obj, options: .PrettyPrinted)
    print(NSString(data: data, encoding: 0)!)
}

let dog = Dog(id: "134", name: "Zarco")
let friends = [Friend(id: "33", name: "a", dog: dog)]
let user = User(id: "1", name: "s", friend: friends)
pprint(JSONAPISerializer(user).customSerialize())

user.data(includeRelationships: true, includeAttributes: true)
[user].data(includeRelationships: true, includeAttributes: true)