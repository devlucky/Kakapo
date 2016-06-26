//
//  Post.swift
//  NewsFeed
//
//  Created by Alex Manzella on 26/06/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo

struct Post: JSONAPIEntity {
    
    let id: String
    let createdAt: Int64
    let updatedAt: Int64
    let systemEntity: RunSession
}