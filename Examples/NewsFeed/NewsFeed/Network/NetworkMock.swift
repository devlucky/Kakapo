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
let store = Store()
let loggedInUser = store.create(User).first!

func startMockingNetwork() {
    let startTime = CFAbsoluteTimeGetCurrent()
    store.create(Post.self, number: 200)
    let endTime = CFAbsoluteTimeGetCurrent()
    print("Created fake Posts in \(endTime - startTime)")
    
    mockNetwork()
}

private func mockNetwork() {
    
    func update<T: protocol<Storable, Serializable>>(entity: T) -> Serializable {
        do {
            try store.update(entity)
            return entity
        } catch {
            return Result.Error("couldn't update \(entity.self).\(entity.id)", 500)
        }
    }
    
    // MARK: Like
    
    func like<T: Likeable>(type: T.Type, with request: Request) -> Serializable {
        let likeableId = request.components["id"]!
        var likeable = store.find(type.self, id: likeableId)!
        let like = store.insert { Like(id: $0, author: loggedInUser) }
        likeable.likes.append(like)
        return update(likeable)
    }
    
    func unlike<T: Likeable>(type: T.Type, with request: Request) -> Serializable {
        let likeableId = request.components["id"]!
        let likeId = request.components["like_id"]!
        var likeable = store.find(type.self, id: likeableId)!
        let index = likeable.likes.indexOf { (like) -> Bool in
            return like.id == likeId && like.author.id == loggedInUser.id
        }
        likeable.likes.removeAtIndex(index!)
        return update(likeable)
    }
    
    func performLikeAction(request: Request, action: (LikeableEntityType) -> (Serializable)) -> Serializable {
        let type = request.components["type"]!
        guard let entityType = LikeableEntityType(rawValue: type) else {
            return Result.Error("Invalid type", 403)
        }
        
        return action(entityType)
    }
    
    router.post("entity/:type/:id/like") { (request) -> Serializable? in
        return performLikeAction(request) { (type) in
            switch type {
            case .Post:
                return like(Post.self, with: request)
            case .Comment:
                return like(Comment.self, with: request)
            }
        }
    }

    router.del("entity/:type/:id/like/:like_id") { (request) -> Serializable? in
        return performLikeAction(request) { (type) in
            switch type {
            case .Post:
                return unlike(Post.self, with: request)
            case .Comment:
                return unlike(Comment.self, with: request)
            }
        }
    }
    
    // MARK: Post
    
    router.get("users/:user_id/newsfeed") { (request) -> Serializable? in
        return store.findAll(Post)
    }
    
    router.get("post/:post_id") { (request) -> Serializable? in
        return store.find(Post.self, id: request.components["post_id"]!)
    }
    
    router.post("post") { (request) -> Serializable? in
        let body = JSON.parse(NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding) as! String)
        return store.insert { (id) -> Post in
            return Post(id: id, text: body["text"].string!, author: loggedInUser)
        }
    }
    
    router.del("post/:post_id") { (request) -> Serializable? in
        let post = store.find(Post.self, id: request.components["post_id"]!)!
        
        do {
            try store.delete(post)
            return Result.Success("deleted")
        } catch {
            return Result.Error("couldn't delete post", 404)
        }
    }
    
    // MARK: Comment
    
    router.post("post/:post_id/comment") { (request) -> Serializable? in
        let body = JSON(request.HTTPBody!)
        var post = store.find(Post.self, id: request.components["post_id"]!)!
        let comment = store.insert { (id) -> Comment in
            return Comment(id: id, author: loggedInUser, text: body["text"].string!)
        }
        post.comments.append(comment)
        return update(post)
    }
    
    router.get("post/:post_id/comment/:comment_id") { (request) -> Serializable? in
        let post = store.find(Post.self, id: request.components["post_id"]!)!
        let index = post.comments.indexOf { $0.id == request.components["comment_id"]! }!
        return post.comments[index]
    }
    
    router.del("post/:post_id/comment/:comment_id") { (request) -> Serializable? in
        var post = store.find(Post.self, id: request.components["post_id"]!)!
        let index = post.comments.indexOf { $0.id == request.components["comment_id"]! }!
        post.comments.removeAtIndex(index)
        return update(post)
    }
}
