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
    static let Post: (String?) -> (String) = { (id) -> String in
        return "/post/\(id ?? ":id")"
    }
}

func setupRoutes(db: KakapoDB) {
    KakapoServer.enable()
    
    db.create(Post.self, number: 10)
    
    KakapoServer.get(Route.Posts) { (request) -> Serializable? in
        db.findAll(Post)
    }
    
    KakapoServer.get(Route.Post(nil)) { (request) -> Serializable? in
        guard let idString = request.info.params["id"], let id = Int(idString) else {
            fatalError()
        }
        return ["post": db.find(Post.self, id: id)]
    }
}