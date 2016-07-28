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
    private let likeView = UIButton()
    private let commentView = UIButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        styleUI()
        layoutUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with post: Post) {
        authorLabel.text = "\(post.author.firstName) \(post.author.lastName)"
        postLabel.text = post.text
    }
    
    private func styleUI() {
        backgroundColor = UIColor.whiteColor()
        postLabel.numberOfLines = 0
    }
    
    private func layoutUI() {
        ([authorLabel, postLabel, avatarImage] as [UIView]).forEach { (view) in
            addSubview(view)
        }
        
        let margin = 10

        authorLabel.snp_makeConstraints { (make) in
            make.top.leading.equalTo(self).offset(margin)
            make.trailing.equalTo(self).inset(margin)
        }
        
        postLabel.snp_makeConstraints { (make) in
            make.top.equalTo(authorLabel.snp_bottom).offset(margin)
            make.leading.trailing.equalTo(authorLabel)
            make.bottom.equalTo(self).inset(margin)
        }
    }
    
}
