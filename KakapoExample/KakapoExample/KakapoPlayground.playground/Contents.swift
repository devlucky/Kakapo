//: Playground - noun: a place where people can play

import UIKit
import Kakapo

struct User: JSONAPIEntity {
    let id: Int
    let name: String
}

let json = JSONAPIRepresentation(User(id: 1, name: "Alex"))
