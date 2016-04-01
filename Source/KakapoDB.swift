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
    
    private var _uuid = 0
    private var store: [String: [KStorable]] = [:]
    
    func create<T: KStorable>(_: T.Type, number: Int) {
        var array = lookup(T)
        for _ in 0..<number {
            array.append(T(id: uuid()))
        }
        store[String(T)] = array
    }
    
    func insert<T: KStorable>(object: T) throws {
        guard object.id > _uuid else {
            throw KakapoDBError.InvalidId
        }
        
        var array = lookup(T)
        array.append(object)
        store[String(T)] = array
        _uuid = object.id + 1
    }
    
    func find<T: KStorable>(_: T.Type, id: Int) -> [T] {
        let array = lookup(T)
        return array.filter{ $0.id == id }.map{ $0 as! T}
    }
    
    private func uuid() -> Int {
        _uuid += 1
        return _uuid
    }
    
    private func lookup<T: KStorable>(_: T.Type) -> [KStorable] {
        return store[String(T)] ?? []
    }
}
