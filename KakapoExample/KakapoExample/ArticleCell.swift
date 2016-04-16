//
//  ArticleCell.swift
//  KakapoExample
//
//  Created by Alex Manzella on 15/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import UIKit

class ArticleCell: UITableViewCell {
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
