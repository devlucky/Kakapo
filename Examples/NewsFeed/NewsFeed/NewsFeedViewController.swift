//
//  NewsFeedViewController.swift
//  NewsFeed
//
//  Created by Alex Manzella on 08/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import UIKit
import SnapKit

class NewsFeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let networkManager: NetworkManager = NetworkManager()
    
    var posts: [Post] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor(white: 0.96, alpha: 1)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.allowsSelection = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "NewsFeed"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: #selector(composePost))
        
        tableView.registerClass(PostTableViewCell.self, forCellReuseIdentifier: String(PostTableViewCell))
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        tableView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        networkManager.postsDidChange.add { [weak self] (posts) in
            self?.posts = posts
        }
        
        networkManager.requestNewsFeed()
    }
    
    @objc private func composePost() {
        let vc = ComposeViewController(networkManager: networkManager)
        let navigationController = UINavigationController(rootViewController: vc)
        presentViewController(navigationController, animated: true, completion: nil)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(String(PostTableViewCell), forIndexPath: indexPath) as! PostTableViewCell
        let post = posts[indexPath.row]
        cell.configure(with: post) { [weak self] in
            self?.networkManager.toggleLikeForPost(at: indexPath.row)
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

