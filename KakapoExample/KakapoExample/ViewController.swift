//
//  ViewController.swift
//  KakapoExample
//
//  Created by Alex Manzella on 29/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import UIKit
import Kakapo
import SnapKit
import SwiftyJSON

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()
    var db: KakapoDB! = nil
    
    var posts = [Post]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        view.addSubview(tableView)
        tableView.registerClass(ArticleCell.self, forCellReuseIdentifier: String(ArticleCell))
        tableView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: Route.Posts)!) { (data, response, _) in
            guard let data = data else { return }
            
            let json = JSON(data: data)
            dispatch_async(dispatch_get_main_queue(), { 
                self.posts = json.arrayValue.map({ (post) -> Post in
                    
                    let comments = post["comments"].arrayValue.map { (comment) -> Comment in
                        return Comment(id: comment["id"].intValue, text: comment["text"].stringValue)
                    }
                    
                    let likes = post["likes"].arrayValue.map { (like) -> Like in
                        let person = like["author"].dictionaryValue
                        return Like(id: like["id"].intValue, author: Person(id: person["id"]!.intValue, name: person["name"]!.stringValue))
                    }
                    
                    return Post(id: post["id"].intValue, content: post["content"].stringValue, comments: comments, likes: likes)
                })
            })
        }.resume()
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
