//
//  NetworkMock.swift
//  NewsFeed
//
//  Created by Alex Manzella on 08/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo

let router = Router.register("https://kakapobook.com/api/newsfeed")
let db = KakapoDB()

func startMockingNetwork() {
    let startTime = CFAbsoluteTimeGetCurrent()
    db.create(Post.self, number: 200)
    let endTime = CFAbsoluteTimeGetCurrent()
    print("Created fake Posts in \(endTime - startTime)")
}