//
//  ModelUtils.swift
//  NewsFeed
//
//  Created by Alex Manzella on 08/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import SwiftyJSON
import Fakery

func random(_ limit: UInt32) -> Int {
    return Int(arc4random() % limit)
}

protocol JSONInitializable {
    init(json: JSON)
}

let sharedFaker = Faker() // apparently very slow, let's use a shared one

extension Faker {
    
    struct FakeDate {
        
        private func dateByAdding(_ days: Int) -> Date {
            var components = DateComponents()
            components.day = days
            return Calendar(identifier: .gregorian).date(byAdding: components, to: Date(), wrappingComponents: true)!
        }
        
        func futureDate() -> Date {
            return dateByAdding(random(10))
        }
        
        func pastDate() -> Date {
            return dateByAdding(-random(10))
        }
    }
    
    var date: FakeDate {
        return FakeDate()
    }
}
