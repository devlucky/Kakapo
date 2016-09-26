//
//  NetworkManager.swift
//  NewsFeed
//
//  Created by Alex Manzella on 28/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Kakapo

class NetworkManager {
    
    private let user = loggedInUser // fake!
    let postsDidChange = ObserverSet<[Post]>()
    var posts: [Post] = [] {
        didSet {
            postsDidChange.notify(posts)
        }
    }
    
    private lazy var manager: SessionManager = {
        let configuration: URLSessionConfiguration = {
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses = [Server.self]
            return configuration
        }()
        
        return SessionManager(configuration: configuration)
    }()
    
    func requestNewsFeed() {
        manager.request("https://kakapobook.com/api/users/\(loggedInUser.id)/newsfeed", method: .get).responseJSON { [weak self] (response) in
            guard let data = response.data else { return }
            let json = JSON(data: data)
            self?.posts = json.arrayValue.map { (post) -> Post in
                return Post(json: post)
            }
        }
    }
    
    func createPost(with text: String) {
        let body = JSON(["text": text]).rawString()
        
        manager.request("https://kakapobook.com/api/post", method: .post, parameters: nil, encoding: body!).responseJSON { [weak self] (response) in
            guard let data = response.data else { return }
            let json = JSON(data: data)
            if var posts = self?.posts {
                posts.insert(Post(json: json), at: 0)
                self?.posts = posts
            }
        }
    }
    
    func toggleLikeForPost(at index: Int) {
        let post = posts[index]
        
        if post.isLikedByMe {
            unlikePost(at: index)
        } else {
            likePost(at: index)
        }
    }
    
    func likePost(at index: Int) {
        let post = posts[index]
        
        manager.request("https://kakapobook.com/api/entity/post/\(post.id)/like", method: .post).responseJSON { [weak self] (response) in
            guard let data = response.data else { return }
            
            let post = Post(json: JSON(data: data))
            
            self?.posts[index] = post
        }
    }
    
    func unlikePost(at index: Int) {
        let post = posts[index]
        let like = post.myLike
        
        manager.request("https://kakapobook.com/api/entity/post/\(post.id)/like/\(like!.id)", method: .delete).responseJSON { [weak self] (response) in
            guard let data = response.data else { return }
            
            let post = Post(json: JSON(data: data))
            
            self?.posts[index] = post
        }
    }
}

extension String: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }    
}
