//
//  PostTableViewCell.swift
//  NewsFeed
//
//  Created by Alex Manzella on 28/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import UIKit
import Haneke

class PostTableViewCell: UITableViewCell {
    
    private static let AvatarPlaceholder = UIImage(named: "avatar_placeholder")
    private static let AvatarSize = 35
    private let authorLabel = UILabel()
    private let postLabel = UILabel()
    private let avatarImage = UIImageView()
    private let likeButton = UIButton()
    private let likeCountLabel = UILabel()
    
    private var likeHandler: (() -> ())?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        styleUI()
        layoutUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImage.hnk_cancelSetImage()
    }
    
    func configure(with post: Post, likeHandler: () -> ()) {
        if let url = NSURL(string: post.author.avatar) {
            avatarImage.hnk_setImageFromURL(url, placeholder: PostTableViewCell.AvatarPlaceholder, format: Format<UIImage>(name: ""))
        }
        authorLabel.text = "\(post.author.firstName) \(post.author.lastName)"
        postLabel.text = post.text
        likeCountLabel.text = "\(post.likes.count)"
        likeButton.tintColor = post.isLikedByMe ? .blueColor() : .grayColor()
        self.likeHandler = likeHandler
    }
    
    private func styleUI() {
        likeButton.setImage(UIImage(named: "thumbUp")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        likeButton.setTitleColor(.blueColor(), forState: .Normal)
        likeButton.addTarget(self, action: #selector(likeButtonPressed), forControlEvents: .TouchUpInside)
        backgroundColor = UIColor.whiteColor()
        postLabel.numberOfLines = 0
        avatarImage.clipsToBounds = true
        avatarImage.contentMode = .ScaleAspectFill
        avatarImage.layer.borderColor = UIColor.lightGrayColor().CGColor
        avatarImage.layer.borderWidth = 0.5
        avatarImage.layer.cornerRadius = CGFloat(PostTableViewCell.AvatarSize / 2)
    }
    
    private func layoutUI() {
        ([authorLabel, postLabel, avatarImage, likeButton, likeCountLabel] as [UIView]).forEach { (view) in
            addSubview(view)
        }
        
        let margin = 10
        
        avatarImage.snp_makeConstraints { (make) in
            make.leading.top.equalTo(margin)
            make.width.height.equalTo(PostTableViewCell.AvatarSize)
        }
        
        authorLabel.snp_makeConstraints { (make) in
            make.leading.equalTo(avatarImage.snp_trailing).offset(margin)
            make.centerY.equalTo(avatarImage)
            make.trailing.equalTo(self).inset(margin)
        }
        
        postLabel.snp_makeConstraints { (make) in
            make.top.equalTo(avatarImage.snp_bottom).offset(margin)
            make.leading.trailing.equalTo(authorLabel)
        }
        
        likeButton.snp_makeConstraints { (make) in
            make.top.equalTo(postLabel.snp_bottom).offset(margin)
            make.leading.equalTo(self).offset(margin)
            make.bottom.equalTo(self).inset(margin)
        }
        
        likeCountLabel.snp_makeConstraints { (make) in
            make.top.bottom.equalTo(likeButton)
            make.leading.equalTo(likeButton.snp_trailing).offset(margin)
        }
    }
    
    @objc private func likeButtonPressed() {
        likeHandler?()
    }
    
}
