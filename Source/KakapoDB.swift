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
    private let queueKey = NSString(string: "dbQueue").UTF8String
    private let _queueContext = NSObject()
    private var queueContext: UnsafeMutablePointer<Void> {
        get {
            return UnsafeMutablePointer<Void>(Unmanaged.passRetained(_queueContext).toOpaque())
        }
    }
    
    private var _uuid = -1
    private var store: [String: ArrayBox<Storable>] = [:]

    public init() {
        dispatch_queue_set_specific(queue, queueKey, queueContext, nil)
    }
    
    private func synchronizeDBWrite(closure: () -> ()) {
        if dispatch_get_specific(queueKey) == queueContext {
            closure()
        } else {
            dispatch_barrier_sync(queue, closure)
        }
    }

    private func synchronizeDBRead(closure: () -> ()) {
        if dispatch_get_specific(queueKey) == queueContext {
            closure()
        } else {
            dispatch_sync(queue, closure)
        }
    }
    
    public func create<T: Storable>(_: T.Type, number: Int = 1) -> [T] {
        var result = [T]()
        
        synchronizeDBWrite {
            result = (0..<number).map { _ in T(id: self.uuid(), db: self) }
            self.lookup(T).value.appendContentsOf(result.flatMap{ $0 as Storable })
        }
        
        return result
    }
    
    public func insert<T: Storable>(handler: (Int) -> T) -> T {
        var obj: T? = nil
        synchronizeDBWrite {
            let potentialId = self._uuid + 1
            let object = handler(potentialId)
            obj = object
            
            if object.id < potentialId {
                fatalError("Tried to insert an invalid id")
            } else {
                self.lookup(T).value.append(object)
                self.uuid()
            }
        }
        return obj!
    }
    
    public func find<T: Storable>(_: T.Type, id: Int) -> T? {
        var result: T?
        
        synchronizeDBRead { [weak self] in
            guard let weakSelf = self else { return }
            
            result = weakSelf.lookup(T).value.filter{ $0.id == id }.flatMap{ $0 as? T }.first
        }
        
        return result
    }
    
    public func findAll<T: Storable>(_: T.Type) -> [T] {
        var result = [T]()
        
        synchronizeDBRead { [weak self] in
            guard let weakSelf = self else { return }
            
            result = weakSelf.lookup(T).value.flatMap{$0 as? T}
        }
        
        return result
    }
    
    public func filter<T: Storable>(_: T.Type, includeElement: (T) -> Bool) -> [T] {
        var result: [T] = []
        
        synchronizeDBRead { [weak self] in
            guard let weakSelf = self else { return }
            
            result = weakSelf.lookup(T).value.flatMap{$0 as? T}.filter(includeElement)
        }
        
        return result
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
