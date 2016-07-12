//
//  Post.swift
//  NewsFeed
//
//  Created by Alex Manzella on 08/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo
import Fakery
import SwiftyJSON

struct Post: Serializable, Storable, JSONInitializable, Likeable {
    
    let id: String
    let date: NSTimeInterval
    var text: String
    let author: User
    var likes: [Like]
    var comments: [Comment]
    
    init(id: String, db: KakapoDB) {
        self.id = id
        date = sharedFaker.date.pastDate().timeIntervalSince1970
        text = sharedFaker.lorem.paragraph(sentencesAmount: random() % 6 + 1)
        author = db.create(User).first!
        likes = db.create(Like.self, number: random(15))
        comments = db.create(Comment.self, number: random(5))
    }
    
    init(json: JSON) {
        id = json["id"].stringValue
        date = json["date"].doubleValue
        text = json["text"].stringValue
        author = User(json: json["author"])
        likes = json["likes"].arrayValue.map { Like(json: $0) }
        comments = json["comments"].arrayValue.map { Comment(json: $0) }
    }
    
    init(id: String, text: String, author: User) {
        self.id = id
        self.text = text
        self.author = author
        date = NSDate().timeIntervalSince1970
        comments = []
        likes = []
    }
}
