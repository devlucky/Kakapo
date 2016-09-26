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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImage.hnk_cancelSetImage()
    }
    
    func configure(with post: Post, likeHandler: @escaping () -> ()) {
        if let url = URL(string: post.author.avatar) {
            avatarImage.hnk_setImageFromURL(url, placeholder: PostTableViewCell.AvatarPlaceholder, format: Format<UIImage>(name: ""))
        }
        authorLabel.text = "\(post.author.firstName) \(post.author.lastName)"
        postLabel.text = post.text
        likeCountLabel.text = "\(post.likes.count)"
        likeButton.tintColor = post.isLikedByMe ? .blue : .gray
        commentCountLabel.text = "\(post.comments.count)"
        self.likeHandler = likeHandler
    }
    
    private func styleUI() {
        authorLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        commentButton.setImage(UIImage(named: "comment")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        commentButton.tintColor = .gray
        likeButton.setImage(UIImage(named: "thumbUp")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        likeButton.addTarget(self, action: #selector(likeButtonPressed), for: .touchUpInside)
        backgroundColor = UIColor.white
        postLabel.numberOfLines = 0
        avatarImage.clipsToBounds = true
        avatarImage.contentMode = .scaleAspectFill
        avatarImage.layer.borderColor = UIColor.lightGray.cgColor
        avatarImage.layer.borderWidth = 0.5
        avatarImage.layer.cornerRadius = CGFloat(PostTableViewCell.AvatarSize / 2)
    }
    
    private func layoutUI() {
        ([authorLabel, postLabel, avatarImage, likeButton, likeCountLabel, commentButton, commentCountLabel] as [UIView]).forEach { (view) in
            addSubview(view)
        }
        
        let margin = 10
        let biggerMargin = 20
        
        avatarImage.snp.makeConstraints { (make) in
            make.leading.top.equalTo(margin)
            make.width.height.equalTo(PostTableViewCell.AvatarSize)
        }
        
        authorLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(avatarImage.snp.trailing).offset(margin)
            make.centerY.equalTo(avatarImage)
            make.trailing.equalTo(self).inset(margin)
        }
        
        postLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avatarImage.snp.bottom).offset(margin)
            make.leading.equalTo(avatarImage.snp.centerX)
            make.trailing.equalTo(authorLabel)
        }
        
        likeButton.snp.makeConstraints { (make) in
            make.top.equalTo(postLabel.snp.bottom).offset(biggerMargin)
            make.leading.equalTo(postLabel)
            make.bottom.equalTo(self).inset(margin)
        }
        
        likeCountLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(likeButton)
            make.leading.equalTo(likeButton.snp.trailing).offset(margin)
        }
        
        commentButton.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(likeButton)
            make.leading.equalTo(likeCountLabel.snp.trailing).offset(biggerMargin)
        }
        
        commentCountLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(likeButton)
            make.leading.equalTo(commentButton.snp.trailing).offset(margin)
        }
    }
    
    @objc private func likeButtonPressed() {
        likeHandler?()
    }
    
}
