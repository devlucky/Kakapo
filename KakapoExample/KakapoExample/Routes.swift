//
//  Routes.swift
//  KakapoExample
//
//  Created by Alex Manzella on 15/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo

struct Route {
    static let Posts = "/posts"
    static let Post = "/post/:id"
}

func setupRoutes(db: KakapoDB) {
    KakapoServer.enable()
    
    db.create(Post.self, number: 10)
    
    KakapoServer.get(Route.Posts) { (request) -> Serializable? in
        db.findAll(Post)
    }
    
    KakapoServer.get(Route.Post) { (request) -> Serializable? in
        guard let idString = request.info.params["id"], let id = Int(idString) else {
            fatalError()
        }
        return db.find(Post.self, id: id)
    }
}