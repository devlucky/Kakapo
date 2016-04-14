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
        
        posts = db.findAll(Post)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        view.addSubview(tableView)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: String(UITableViewCell))
        tableView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }

    func setup() {
        KakapoServer.enable()
        
        db.create(Post.self, number: 10)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(String(UITableViewCell))!
        let post = posts[indexPath.row]
        cell.textLabel?.text = post.content
        cell.detailTextLabel?.text = "\(post.likes.count) ❤️ \(post.comments.count) 💬"
        return cell
    }
}

