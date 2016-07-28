//
//  PostTableViewCell.swift
//  NewsFeed
//
//  Created by Alex Manzella on 28/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    private let authorLabel = UILabel()
    private let postLabel = UILabel()
    private let avatarImage = UIImageView()
    private let likeButton = UIButton()
    private let likeCountLabel = UILabel()
    private let commentButton = UIButton()
    private let commentCountLabel = UILabel()
    
    private var likeHandler: (() -> ())?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        styleUI()
        layoutUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with post: Post, likeHandler: () -> ()) {
        authorLabel.text = "\(post.author.firstName) \(post.author.lastName)"
        postLabel.text = post.text
        likeCountLabel.text = "\(post.likes.count)"
        likeButton.tintColor = post.isLikedByMe ? .blueColor() : .grayColor()
        commentCountLabel.text = "\(post.comments.count)"
        self.likeHandler = likeHandler
    }
    
    private func styleUI() {
        commentButton.setImage(UIImage(named: "comment")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        commentButton.tintColor = .grayColor()
        likeButton.setImage(UIImage(named: "thumbUp")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        likeButton.addTarget(self, action: #selector(likeButtonPressed), forControlEvents: .TouchUpInside)
        backgroundColor = UIColor.whiteColor()
        postLabel.numberOfLines = 0
    }
    
    private func layoutUI() {
        ([authorLabel, postLabel, avatarImage, likeButton, likeCountLabel, commentButton, commentCountLabel] as [UIView]).forEach { (view) in
            addSubview(view)
        }
        
        let margin = 10
        let biggerMargin = 20

        authorLabel.snp_makeConstraints { (make) in
            make.top.leading.equalTo(self).offset(margin)
            make.trailing.equalTo(self).inset(margin)
        }
        
        postLabel.snp_makeConstraints { (make) in
            make.top.equalTo(authorLabel.snp_bottom).offset(margin)
            make.leading.trailing.equalTo(authorLabel)
        }
        
        likeButton.snp_makeConstraints { (make) in
            make.top.equalTo(postLabel.snp_bottom).offset(biggerMargin)
            make.leading.equalTo(self).offset(margin)
            make.bottom.equalTo(self).inset(margin)
        }
        
        likeCountLabel.snp_makeConstraints { (make) in
            make.top.bottom.equalTo(likeButton)
            make.leading.equalTo(likeButton.snp_trailing).offset(margin)
        }
        
        commentButton.snp_makeConstraints { (make) in
            make.top.bottom.equalTo(likeButton)
            make.leading.equalTo(likeCountLabel.snp_trailing).offset(biggerMargin)
        }
        
        commentCountLabel.snp_makeConstraints { (make) in
            make.top.bottom.equalTo(likeButton)
            make.leading.equalTo(commentButton.snp_trailing).offset(margin)
        }
    }
    
    @objc private func likeButtonPressed() {
        likeHandler?()
    }
    
}
