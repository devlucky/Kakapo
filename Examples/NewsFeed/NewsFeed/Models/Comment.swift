//
//  Comment.swift
//  NewsFeed
//
//  Created by Alex Manzella on 08/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo
import Fakery
import SwiftyJSON

struct Comment: Serializable, Storable, JSONInitializable, Likeable {
    
    let id: String
    let author: User
    let text: String
    var likes: [Like]
    
    init(id: String, db: KakapoDB) {
        self.id = id
        author = db.create(User).first!
        text = sharedFaker.lorem.paragraph(sentencesAmount: random(3) + 1)
        likes = db.create(Like.self, number: random(5))
    }
    
    init(json: JSON) {
        id = json["id"].stringValue
        author = User(json: json["author"])
        text = json["text"].stringValue
        likes = json["likes"].arrayValue.map { Like(json: $0) }
    }
    
    init(id: String, author: User, text: String) {
        self.id = id
        self.author = author
        self.text = text
        likes = []
    }
}
