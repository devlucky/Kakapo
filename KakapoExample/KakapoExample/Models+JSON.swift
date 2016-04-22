//
//  Models+JSON.swift
//  KakapoExample
//
//  Created by Alex Manzella on 22/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import SwiftyJSON

extension Person {
    init(json: JSON) {
        id = json["id"].intValue
        name = json["name"].stringValue
    }
}

extension Like {
    init(json: JSON) {
        id = json["id"].intValue
        author = Person(json: json["author"])
    }
}

extension Comment {
    init(json: JSON) {
        id = json["id"].intValue
        text = json["text"].stringValue
    }
}

extension Post {
    init(json: JSON) {
        id = json["id"].intValue
        title = json["title"].stringValue
        content = json["content"].stringValue
        comments = json["comments"].arrayValue.map { Comment(json: $0) }
        likes = json["likes"].arrayValue.map { Like(json: $0) }
    }
}
