//
//  User.swift
//  NewsFeed
//
//  Created by Alex Manzella on 08/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo
import Fakery
import SwiftyJSON

struct User: Serializable, Storable, JSONInitializable {
    
    let id: String
    let firstName: String
    let lastName: String
    let avatar: String
    
    init(id: String, db: KakapoDB) {
        self.id = id
        firstName = sharedFaker.name.firstName()
        lastName = sharedFaker.name.lastName()
        avatar = "https://robohash.org/\(arc4random())"
    }
    
    init(json: JSON) {
        id = json["id"].stringValue
        firstName = json["firstName"].stringValue
        lastName = json["lastName"].stringValue
        avatar = json["avatar"].stringValue
    }
}
