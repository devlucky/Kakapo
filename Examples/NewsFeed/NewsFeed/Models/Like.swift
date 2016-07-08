//
//  Like.swift
//  NewsFeed
//
//  Created by Alex Manzella on 08/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo
import Fakery
import SwiftyJSON

struct Like: Storable, JSONInitializable {
    
    let id: String
    let author: User
    
    init(id: String, db: KakapoDB) {
        self.id = id
        author = db.create(User).first!
    }
    
    init(json: JSON) {
        id = json["id"].stringValue
        author = User(json: json["author"])
    }
}
