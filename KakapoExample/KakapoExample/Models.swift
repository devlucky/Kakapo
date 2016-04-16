//
//  Models.swift
//  KakapoExample
//
//  Created by Alex Manzella on 15/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo
import Fakery

let sharedFaker = Faker()

struct Person: Serializable, Storable {
    let id: Int
    let name: String
    
    init(id: Int, db: KakapoDB) {
        self.id = id
        self.name = sharedFaker.name.name()
    }
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

struct Comment: Serializable, Storable {
    let id: Int
    let text: String

    init(id: Int, db: KakapoDB) {
        self.id = id
        self.text = sharedFaker.lorem.sentence()
    }
    
    init(id: Int, text: String) {
        self.id = id
        self.text = text
    }
}

struct Like: Serializable, Storable {
    let id: Int
    let author: Person
    
    init(id: Int, db: KakapoDB) {
        self.id = id
        self.author = db.insert { Person(id: $0, db: db) }
    }
    
    init(id: Int, author: Person) {
        self.id = id
        self.author = author
    }
}

struct Post: Serializable, Storable {
    let id: Int
    let content: String
    let comments: [Comment]
    let likes: [Like]
    
    init(id: Int, db: KakapoDB) {
        self.id = id
        self.content = sharedFaker.lorem.paragraph(sentencesAmount: random() % 30 + 1)
        self.comments = db.create(Comment.self, number: random() % 5)
        self.likes = db.create(Like.self, number: random() % 30)
    }
    
    init(id: Int, content: String, comments: [Comment], likes: [Like]) {
        self.id = id
        self.content = content
        self.comments = comments
        self.likes = likes
    }
}
