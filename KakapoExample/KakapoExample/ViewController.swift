//
//  ViewController.swift
//  KakapoExample
//
//  Created by Alex Manzella on 29/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import UIKit
import Kakapo
import Fakery
import SnapKit

let sharedFaker = Faker()

struct Person: Serializable, Storable {
    let id: Int
    let name: String
    
    init(id: Int, db: KakapoDB) {
        self.id = id
        self.name = sharedFaker.name.name()
    }
}

struct Comment: Serializable, Storable {
    let id: Int
    let text: String

    init(id: Int, db: KakapoDB) {
        self.id = id
        self.text = sharedFaker.lorem.sentence()
    }
}

struct Like: Serializable, Storable {
    let id: Int
    let author: Person
    
    init(id: Int, db: KakapoDB) {
        self.id = id
        self.author = db.insert { Person(id: $0, db: db) }
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

class ArticleCell: UITableViewCell {
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let db = KakapoDB()
    let tableView = UITableView()
    var posts = [Post]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        view.addSubview(tableView)
        tableView.registerClass(ArticleCell.self, forCellReuseIdentifier: String(ArticleCell))
        tableView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "/posts")!) { (data, response, _) in
            let posts = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as! [AnyObject]
            dispatch_async(dispatch_get_main_queue(), { 
                self.posts = posts.map({ (dict) -> Post in
                    return Post(id: dict["id"] as! Int, content: dict["content"] as! String, comments: [], likes: [])
                })
            })
        }.resume()
    }

    func setup() {
        KakapoServer.enable()
        
        db.create(Post.self, number: 10)
        
        KakapoServer.get("/posts") { (request) -> Serializable? in
            self.db.findAll(Post)
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(String(ArticleCell))!
        let post = posts[indexPath.row]
        cell.textLabel?.text = post.content
        cell.detailTextLabel?.text = "\(post.likes.count) ❤️ \(post.comments.count) 💬"
        return cell
    }
}

