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

func random(limit: UInt32) -> Int {
    return Int(arc4random() % limit)
}

protocol JSONInitializable {
    init(json: JSON)
}

let sharedFaker = Faker() // apparently very slow, let's use a shared one

extension Faker {
    
    struct Date {
        
        private func dateByAdding(days: Int) -> NSDate {
            let components = NSDateComponents()
            components.day = days
            return NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!.dateByAddingComponents(components, toDate: NSDate(), options: .WrapComponents)!
        }
        
        func futureDate() -> NSDate {
            return dateByAdding(random(10))
        }
        
        func pastDate() -> NSDate {
            return dateByAdding(-random(10))
        }
    }
    
    var date: Date {
        return Date()
    }
}