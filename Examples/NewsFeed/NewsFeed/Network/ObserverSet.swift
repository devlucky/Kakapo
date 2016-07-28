//
//  ObserverSet.swift
//  ObserverSet
//
//  Created by Mike Ash on 1/22/15.
//  Copyright (c) 2015 Mike Ash. All rights reserved.
//

import Foundation

public class ObserverSetEntry<Parameters> {
    private weak var object: AnyObject?
    private let f: AnyObject -> Parameters -> Void
    
    private init(object: AnyObject, f: AnyObject -> Parameters -> Void) {
        self.object = object
        self.f = f
    }
}


public class ObserverSet<Parameters>: CustomStringConvertible {
    // Locking support
    
    private var queue = dispatch_queue_create("com.mikeash.ObserverSet", nil)
    
    private func synchronized(f: Void -> Void) {
        dispatch_sync(queue, f)
    }
    
    
    // Main implementation
    
    private var entries: [ObserverSetEntry<Parameters>] = []
    
    public init() {}
    
    public func add<T: AnyObject>(object: T, _ f: T -> Parameters -> Void) -> ObserverSetEntry<Parameters> {
        let entry = ObserverSetEntry<Parameters>(object: object, f: { f($0 as! T) })
        synchronized {
            self.entries.append(entry)
        }
        return entry
    }
    
    public func add(f: Parameters -> Void) -> ObserverSetEntry<Parameters> {
        return self.add(self, { ignored in f })
    }
    
    public func remove(entry: ObserverSetEntry<Parameters>) {
        synchronized {
            self.entries = self.entries.filter{ $0 !== entry }
        }
    }
    
    public func notify(parameters: Parameters) {
        var toCall: [Parameters -> Void] = []
        
        synchronized {
            for entry in self.entries {
                if let object: AnyObject = entry.object {
                    toCall.append(entry.f(object))
                }
            }
            self.entries = self.entries.filter{ $0.object != nil }
        }
        
        for f in toCall {
            f(parameters)
        }
    }
    
    
    // Printable
    
    public var description: String {
        var entries: [ObserverSetEntry<Parameters>] = []
        synchronized {
            entries = self.entries
        }
        
        let strings = entries.map{
            entry in
            (entry.object === self
                ? "\(entry.f)"
                : "\(entry.object) \(entry.f)")
        }
        let joined = strings.joinWithSeparator(", ")
        
        return "\(Mirror(reflecting: self).description): (\(joined))"
    }
}

