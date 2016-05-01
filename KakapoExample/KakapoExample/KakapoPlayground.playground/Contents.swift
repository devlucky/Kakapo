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
