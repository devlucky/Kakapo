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
        
        title = "Posts"
        
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
                self.posts = json.arrayValue.map { Post(json: $0) }
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
        cell.textLabel?.text = post.title
        cell.detailTextLabel?.text = "\(post.likes.count) ❤️ \(post.comments.count) 💬"
        return cell
    }

    // MARK: UITableViewelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let postId = String(posts[indexPath.row].id)
        navigationController?.pushViewController(PostViewController(postId: postId), animated: true)
    }

}
