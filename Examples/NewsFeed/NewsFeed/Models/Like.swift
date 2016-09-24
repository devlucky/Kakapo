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

enum LikeableEntityType: String {
    case Post = "post"
    case Comment = "comment"
}

protocol Likeable: Storable, Serializable {
    var likes: [Like] { get set}
}

struct Like: Serializable, Storable, JSONInitializable {
    
    let id: String
    let author: User
    
    init(id: String, store: Store) {
        self.id = id
        author = store.create(User.self).first!
    }
    
    init(json: JSON) {
        id = json["id"].stringValue
        author = User(json: json["author"])
    }
    
    init(id: String, author: User) {
        self.id = id
        self.author = author
    }
}
