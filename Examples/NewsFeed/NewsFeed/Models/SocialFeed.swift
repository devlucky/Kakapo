//
//  SocialFeed.swift
//  NewsFeed
//
//  Created by Alex Manzella on 26/06/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo

struct SocialFeed: JSONAPIEntity {
    
    let id: String
    let posts: [Post]
    let user: User
}