//: Playground - noun: a place where people can play

import UIKit
@testable import Kakapo

struct User: JSONAPIEntity {
    let id: Int
    let name: String
}

let json = JSONAPIRepresentation(User(id: 1, name: "Alex"))
json.serialize()


struct PlainRepresentation<T>: Serializable, CustomReflectable {
    let object: T
    let key: String
    
    init(_ obj: T, key: String) {
        object = obj
        self.key = key
    }
    
    func customMirror() -> Mirror {
        return Mirror(object, children: [key: object])
    }
}

struct CustomRepresentation<T>: Serializable, CustomReflectable {
    let top: T
    let bottom: T
    let error: String
    
    func customMirror() -> Mirror {
        return Mirror(self, children: ["_top": top, "wdw": 1])
    }
}

User(id: 2, name: "3").serialize()

PlainRepresentation([User(id: 1, name: "Alex")], key: "users").serialize()

//func serialize(serializable: Serializable, key: String) -> [String: Any] {
//    return serialize(PlainRepresentation(serializable, key: key))
//}

CustomRepresentation(top: [User(id: 1, name: "Alex")], bottom: [User(id: 1, name: "Alex")], error: "404").serialize()


KakapoServer.get("") { (request) in
    return PlainRepresentation([User(id: 1, name: "Alex")], key: "users")
}


[User(id: 1, name: "Alex")].serialize()
["test": [User(id: 1, name: "Alex")]].serialize()
Optional([User(id: 1, name: "Alex")]).serialize()
IgnorableNilProperty([User(id: 1, name: "Alex")]).serialize()
