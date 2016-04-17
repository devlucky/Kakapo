//
//  KakapoDB.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

public protocol Storable {
    var id: Int { get }
    init(id: Int, db: KakapoDB)
}

enum KakapoDBError: ErrorType {
    case InvalidId
}

/**
 We use an array box because the array is stored in a Dictionary and we want to mutate it.
 Without a box the Array has to be assigned to a var to be mutated therefore is not uniquely referenced and we loose the copy-on-write optimization; performance would be quite poor for multiple insertion (about 97%).
 
 **[See issue #17](https://github.com/devlucky/Kakapo/issues/17)**
*/
private final class ArrayBox<T> {
    private init(_ value: [T]) {
        self.value = value
    }
    
    private var value: [T]
}

public class KakapoDB {
    
    private let queue = dispatch_queue_create("com.kakapodb.queue", DISPATCH_QUEUE_CONCURRENT)
    private var _uuid = -1
    private var store: [String: ArrayBox<Storable>] = [:]

    public init() {
        // empty but needed to be initialized from other modules.
    }
    
    private func barrierSync<T>(closure: () -> T) -> T {
        var object: T?
        dispatch_barrier_sync(queue) {
            object = closure()
        }
        return object!
    }

    private func barrierAsync(closure: () -> ()) {
        dispatch_barrier_async(queue, closure)
    }

    private func sync(closure: () -> ()) {
        dispatch_sync(queue, closure)
    }
    
    public func create<T: Storable>(_: T.Type, number: Int = 1) -> [T] {
        let ids = barrierSync {
            return (0..<number).map { _ in self.uuid()}
        }
        
        let result = ids.map { id in T(id: id, db: self) }
        barrierAsync {
            self.lookup(T).value.appendContentsOf(result.flatMap{ $0 as Storable })
        }
        
        return result
    }
    
    public func insert<T: Storable>(handler: (Int) -> T) -> T {
        let id = barrierSync {
            return self.uuid()
        }
        
        let object = handler(id)
            
        precondition(object.id == id, "Tried to insert an invalid id")
        barrierAsync {
            self.lookup(T).value.append(object)
        }

        return object
    }
    
    public func find<T: Storable>(_: T.Type, id: Int) -> T? {
        return filter(T.self) { $0.id == id }.first
    }
    
    public func findAll<T: Storable>(_: T.Type) -> [T] {
        var result = [T]()
        
        sync { [weak self] in
            guard let weakSelf = self else { return }
            
            result = weakSelf.lookup(T).value.flatMap{$0 as? T}
        }
        
        return result
    }
    
    public func filter<T: Storable>(_: T.Type, includeElement: (T) -> Bool) -> [T] {
        return findAll(T).filter(includeElement)
    }
    
    private func uuid() -> Int {
        _uuid += 1
        return _uuid
    }
    
    private func lookup<T: Storable>(_: T.Type) -> ArrayBox<Storable> {
        var boxedArray: ArrayBox<Storable>
        
        if let storedBoxedArray = store[String(T)] {
            boxedArray = storedBoxedArray
        } else {
            boxedArray = ArrayBox<Storable>([])
            store[String(T)] = boxedArray
        }
        
        return boxedArray
    }
}
