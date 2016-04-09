//
//  KakapoDB.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

protocol KStorable {
    var id: Int { get }
    init(id: Int)
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

class KakapoDB {
    
    private let queue = dispatch_queue_create("com.kakapodb.queue", DISPATCH_QUEUE_CONCURRENT)
    private var _uuid = -1
    private var store: [String: ArrayBox<KStorable>] = [:]
    
    func create<T: KStorable>(_: T.Type, number: Int = 1) -> [KStorable] {
        var result: [KStorable] = []
        
        dispatch_barrier_sync(queue) { [weak self] in
            guard let weakSelf = self else { return }
            
            result = (0..<number).map { _ in T(id: weakSelf.uuid()) }
            weakSelf.lookup(T).value.appendContentsOf(result)
        }
        
        return result
    }
    
    func insert<T: KStorable>(handler: (Int) -> T) {
        dispatch_barrier_async(queue) { [weak self] in
            guard let weakSelf = self else { return }
            
            let potentialId = weakSelf._uuid + 1
            let object = handler(potentialId)
            
            if object.id < potentialId {
                fatalError("Tried to insert an invalid id")
            } else {
                weakSelf.lookup(T).value.append(object)
                weakSelf.uuid()
            }
        }
    }
    
    func find<T: KStorable>(_: T.Type, id: Int) -> T? {
        var result: T?
        
        dispatch_sync(queue) { [weak self] in
            guard let weakSelf = self else { return }
            
            result = weakSelf.lookup(T).value.filter{ $0.id == id }.flatMap{ $0 as? T }.first
        }
        
        return result
    }
    
    func findAll<T: KStorable>(_: T.Type) -> [T] {
        var result = [T]()
        
        dispatch_sync(queue) { [weak self] in
            guard let weakSelf = self else { return }
            
            result = weakSelf.lookup(T).value.map{$0 as! T}
        }
        
        return result
    }
    
    func filter<T: KStorable>(_: T.Type, includeElement: (T) -> Bool) -> [T] {
        var result: [T] = []
        
        dispatch_sync(queue) { [weak self] in
            guard let weakSelf = self else { return }
            
            result = weakSelf.lookup(T).value.map{$0 as! T}.filter(includeElement)
        }
        
        return result
    }
    
    private func uuid() -> Int {
        _uuid += 1
        return _uuid
    }
    
    private func lookup<T: KStorable>(_: T.Type) -> ArrayBox<KStorable> {
        var boxedArray: ArrayBox<KStorable>
        
        if let storedBoxedArray = store[String(T)] {
            boxedArray = storedBoxedArray
        } else {
            boxedArray = ArrayBox<KStorable>([])
            store[String(T)] = boxedArray
        }
        
        return boxedArray
    }
}
