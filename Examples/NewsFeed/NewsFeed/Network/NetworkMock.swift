//
//  NetworkMock.swift
//  NewsFeed
//
//  Created by Alex Manzella on 08/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo
import SwiftyJSON

enum Result: ResponseFieldsProvider {
    case Success(String)
    case Error(String, Int)
    
    var statusCode: Int {
        switch self {
        case let .Error(_, code):
            return code
        default:
            return 200
        }
    }
    
    var body: Serializable {
        switch self {
        case let .Success(value):
            return ["success": value]
        case let .Error(value, _):
            return ["error": value]
        }
    }
    
    var headerFields: [String : String]? {
        return nil
    }
}

let router = Router.register("https://kakapobook.com/api/")
let db = KakapoDB()
let loggedInUser = db.create(User).first!

func startMockingNetwork() {
    let startTime = CFAbsoluteTimeGetCurrent()
    db.create(Post.self, number: 200)
    let endTime = CFAbsoluteTimeGetCurrent()
    print("Created fake Posts in \(endTime - startTime)")
    
    mockNetwork()
}

private func mockNetwork() {
    
    func update<T: protocol<Storable, Serializable>>(entity: T) -> Serializable {
        do {
            try db.update(entity)
            return entity
        } catch {
            return Result.Error("couldn't update \(entity.self).\(entity.id)", 500)
        }
    }
    
    // MARK: Like
    
    func like<T: Likeable>(type: T.Type, with request: Request) -> Serializable {
        let likeableId = request.components["id"]!
        var likeable = db.find(T.self, id: likeableId)!
        let like = db.insert { Like(id: $0, author: loggedInUser) }
        likeable.likes.append(like)
        return update(likeable)
    }
    
    func unlike<T: Likeable>(type: T.Type, with request: Request) -> Serializable {
        let likeableId = request.components["id"]!
        var likeable = db.find(T.self, id: likeableId)!
        let index = likeable.likes.indexOf { (like) -> Bool in
            return like.author.id == loggedInUser.id
        }
        likeable.likes.removeAtIndex(index!)
        return update(likeable)
    }
    
    router.put("post/like/:id") { (request) -> Serializable? in
        return like(Post.self, with: request)
    }

    router.put("comment/like/:id") { (request) -> Serializable? in
        return like(Comment.self, with: request)
    }

    router.del("post/like/:id") { (request) -> Serializable? in
        return unlike(Post.self, with: request)
    }
    
    router.del("comment/like/:id") { (request) -> Serializable? in
        return unlike(Comment.self, with: request)
    }
    
    // MARK: Post
    
    router.get("newsfeed") { (request) -> Serializable? in
        return db.findAll(Post)
    }
    
    router.get("post/:postid") { (request) -> Serializable? in
        return db.find(Post.self, id: request.components["postid"]!)
    }
    
    router.put("post") { (request) -> Serializable? in
        let body = JSON(request.HTTPBody!)
        return db.insert { (id) -> Post in
            return Post(id: id, text: body["text"].string!, author: loggedInUser)
        }
    }
    
    router.del("post/:postid") { (request) -> Serializable? in
        let post = db.find(Post.self, id: request.components["postid"]!)!
        
        do {
            try db.delete(post)
            return Result.Success("deleted")
        } catch {
            return Result.Error("couldn't delete post", 404)
        }
    }
    
    // MARK: Comment
    
    router.put("post/:postid/comment") { (request) -> Serializable? in
        let body = JSON(request.HTTPBody!)
        var post = db.find(Post.self, id: request.components["postid"]!)!
        let comment = db.insert{ (id) -> Comment in
            return Comment(id: id, author: loggedInUser, text: body["text"].string!)
        }
        post.comments.append(comment)
        return update(post)
    }
    
    router.get("post/:postid/comment/:commentid") { (request) -> Serializable? in
        let post = db.find(Post.self, id: request.components["postid"]!)!
        let index = post.comments.indexOf { $0.id == request.components["commentid"]! }!
        return post.comments[index]
    }
    
    router.del("post/:postid/comment/:commentid") { (request) -> Serializable? in
        var post = db.find(Post.self, id: request.components["postid"]!)!
        let index = post.comments.indexOf { $0.id == request.components["commentid"]! }!
        post.comments.removeAtIndex(index)
        return update(post)
    }
}