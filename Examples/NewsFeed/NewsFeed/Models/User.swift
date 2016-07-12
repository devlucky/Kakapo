//
//  User.swift
//  NewsFeed
//
//  Created by Alex Manzella on 26/06/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo

struct User: JSONAPIEntity {
    
    let id: String
    let firstName: String
    let lastName: String
    let avatar: Avatar
}