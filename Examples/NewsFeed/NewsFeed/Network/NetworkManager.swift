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
    
    private lazy var manager: Manager = {
        let configuration: NSURLSessionConfiguration = {
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            configuration.protocolClasses = [KakapoServer.self]
            return configuration
        }()
        
        return Manager(configuration: configuration)
    }()
    
    func requestNewsFeed() {
        manager.request(.GET, "https://kakapobook.com/api/users/\(loggedInUser.id)/newsfeed").responseJSON { [weak self] (response) in
            guard let data = response.data else { return }
            let json = JSON(data: data)
            self?.posts = json.arrayValue.map { (post) -> Post in
                return Post(json: post)
            }
        }
    }
    
    func createPost(with text: String) {
        manager.request(.POST, "https://kakapobook.com/api/post", parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.HTTPBody = JSON(["text": text]).rawString()?.dataUsingEncoding(NSUTF8StringEncoding)
            return (mutableRequest, nil)
        })).responseJSON { [weak self] (response) in
            guard let data = response.data else { return }
            let json = JSON(data: data)
            if var posts = self?.posts {
                posts.insert(Post(json: json), atIndex: 0)
                self?.posts = posts
            }
        }
    }
    
    func likePost(at index: Int) {
        let post = posts[index]
        
        manager.request(.POST, "https://kakapobook.com/api/entity/post/\(post.id)/like").responseJSON{ [weak self] (response) in
            guard let data = response.data else { return }
            
            let post = Post(json: JSON(data: data))
            
            self?.posts[index] = post
        }
    }
    
    func unlikePost(at index: Int) {
        let post = posts[index]
        let like = post.myLike
        
        manager.request(.DELETE, "https://kakapobook.com/api/entity/post/\(post.id)/like/\(like!.id)").responseJSON{ [weak self] (response) in
            guard let data = response.data else { return }
            
            let post = Post(json: JSON(data: data))
            
            self?.posts[index] = post
        }
    }
}