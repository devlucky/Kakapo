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
    
    func create<T: KStorable>(_: T.Type, number: Int) -> [KStorable] {
        var result: [KStorable] = []
        
        dispatch_barrier_sync(queue) { [weak self] in
            guard let weakSelf = self else { return }
            
            let arrayBox = weakSelf.lookup(T)
            result = (0..<number).map { _ in T(id: weakSelf.uuid()) }
            arrayBox.value.appendContentsOf(result)
            weakSelf.store[String(T)] = arrayBox
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
                let arrayBox = weakSelf.lookup(T)
                arrayBox.value.append(object)
                weakSelf.store[String(T)] = arrayBox
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
        return store[String(T)] ?? ArrayBox<KStorable>([])
    }
}
