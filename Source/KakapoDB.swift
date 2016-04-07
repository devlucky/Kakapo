//
//  KakapoDB.swift
//  KakapoExample
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

class KakapoDB {
    
    private let queue = dispatch_queue_create("com.kakapodb.queue", DISPATCH_QUEUE_CONCURRENT)
    private var _uuid = -1
    private var store: [String: [KStorable]] = [:]
    
    func create<T: KStorable>(_: T.Type, number: Int) {
        dispatch_barrier_async(queue) { [weak self] in
            guard let weakSelf = self else { return }
            
            var array = weakSelf.lookup(T)
            for _ in 0..<number {
                array.append(T(id: weakSelf.uuid()))
            }
            weakSelf.store[String(T)] = array
        }
    }
    
    func insert<T: KStorable>(object: T) throws {
        guard object.id > _uuid else {
            throw KakapoDBError.InvalidId
        }
        
        dispatch_barrier_async(queue) { [weak self] in
            guard let weakSelf = self else { return }
            
            var array = weakSelf.lookup(T)
            array.append(object)
            weakSelf.store[String(T)] = array
            weakSelf._uuid = object.id + 1
        }
    }
    
    func find<T: KStorable>(_: T.Type, id: Int) -> T? {
        var result: T?
        
        dispatch_sync(queue) { [weak self] in
            guard let weakSelf = self else { return }
            
            let array = weakSelf.lookup(T)
            
            result = array.filter{ $0.id == id }.flatMap{ $0 as? T }.first
        }
        
        return result
    }
    
    func filter<T: KStorable>(_: T.Type, includeElement: (T) -> Bool) -> [T] {
        var result: [T] = []
        
        dispatch_sync(queue) { [weak self] in
            guard let weakSelf = self else { return }
            
            let array = weakSelf.lookup(T).map{$0 as! T}
            
            result = array.filter(includeElement)
        }
        
        return result
    }
    
    private func uuid() -> Int {
        _uuid += 1
        return _uuid
    }
    
    private func lookup<T: KStorable>(_: T.Type) -> [KStorable] {
        return store[String(T)] ?? []
    }
}
