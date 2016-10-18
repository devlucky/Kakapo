//
//  Store.swift
//  Kakapo
//
//  Created by Joan Romano on 31/03/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation

/**
 A base protocol providing basic storage behavior with an `id` and a generic `init` method for all objects that will be inserted. 
 */
public protocol Storable {
    /// The unique identifier provided by `Store`, objects shouldn't generate ids themselves. `Store` generate `Int` ids converted to String for better compatibilities with standards like JSONAPI, in case you need `Int` ids is safe to assume that the conversion will always succeeed.
    var id: String { get }
    
    /**
     An initializer that is used by `Store` to create objects to be stored in the store
     
     - parameter id: The unique identifier provided by `Store`, objects shouldn't generate ids themselves. `Store` generate `Int` ids converted to String for better compatibilities with standards like JSONAPI, in case you need `Int` ids is safe to ssume that the conversion will always succeeed.
     - parameter store: The store that is creating the object, can be used  to generate other `Storable` objects, for example relationships of the object: `myRelationship = store.create(MyRelationshipType)` or `myrelationship = store.insert { MyRelationshipType(id: $0, store: store) }`. The relationsip will also recieve the `store` instance to eventually initialize its relationships.
     
     - returns: A configured object stored in the store.
     */
    init(id: String, store: Store)
}

enum StoreError: Error {
    case invalidEntity
}

/**
 We use an array box because the array is stored in a Dictionary and we want to mutate it.
 Without a box the Array has to be assigned to a var to be mutated therefore is not uniquely referenced and we loose the copy-on-write optimization; performance would be quite poor for multiple insertion (about 97%).
 
 **[See issue #17](https://github.com/devlucky/Kakapo/issues/17)**
*/
private final class ArrayBox<T> {
    fileprivate init(_ value: [T]) {
        self.value = value
    }
    
    fileprivate var value: [T]
}

/**
 An in-memory store that holds state supporting insertion, deletion, updating and finding.
 
 You can use this class together with a Router to achieve the behavior you want after some request is done. An example
 could be returning an User after a get request with that User's id:
 
    let store = Store()
    store.create(User.self, number: 20)
 
    router.get("/users/:id") { request in
        return store.find(User.self, id: someId)
    }
 
 In order for your classes to be used by the `Store`, they must conform to the `Storable` protocol. For more info about `Router` and `Serializable`, check the `Router` class documentation.
 */
public final class Store {
    
    private let queue = DispatchQueue(label: "com.store.queue", attributes: .concurrent)
    private var uuid = -1
    private var store: [String: ArrayBox<Storable>] = [:]

    /// Initialize a new in-memory store
    public init() {
        // empty but needed to be initialized from other modules.
    }
    
    private func barrierSync<T>(_ closure: () -> T) -> T {
        var object: T!
        queue.sync(flags: .barrier) {
            object = closure()
        }
        return object
    }

    private func barrierAsync(_ closure: @escaping () -> ()) {
        queue.async(flags: .barrier, execute: closure)
    }

    private func sync<T>(_ closure: () -> T) -> T {
        var object: T!
        queue.sync {
            object = closure()
        }
        return object
    }
    
    /**
     Creates and inserts Storable objects based on their default initializer
     
     - parameter (unnamed): The Storable Type to be created
     - parameter number: The number of elements to create, defaults to 1
     
     - returns: An array containing the new inserted Storable objects
     */
    @discardableResult public func create<T: Storable>(_: T.Type, number: Int = 1) -> [T] {
        let ids = barrierSync {
            return (0..<number).map { _ in self.generateUUID()}
        }
        
        let objects = ids.map { id in T(id: id, store: self) }
        
        barrierAsync {
            self.lookup(T.self).value.append(contentsOf: objects.flatMap { $0 as Storable })
        }
        
        return objects
    }
    
    /**
     Creates an inserts an Storable object returned by a given handler
     
     - parameter handler: A handler that will be called with a new `id` and will return the new Storable element to be inserted. The `id` needs to be used when creating the new Storable element, otherwise this method will assert.
     
     - returns: The new inserted Storable object
     */
    @discardableResult public func insert<T: Storable>(_ handler: (String) -> T) -> T {
        let id = barrierSync {
            return self.generateUUID()
        }
        
        let object = handler(id)
            
        precondition(object.id == id, "Tried to insert an invalid id")
        barrierAsync {
            self.lookup(T.self).value.append(object)
        }

        return object
    }
    
    /**
     Updates the given Storable object
     
     - parameter entity: The Storable object to be updated
     
     - throws: `StoreError.invalidEntity` if no Storable object with same `id` was found
     */
    public func update<T: Storable>(_ entity: T) throws {
        let updated: Bool = barrierSync {
            let index = self.lookup(T.self).value.index { $0.id == entity.id }
            guard let indexToUpdate = index else { return false }
            self.lookup(T.self).value[indexToUpdate] = entity
            
            return true
        }
        
        if !updated {
            throw StoreError.invalidEntity
        }
    }
    
    /**
     Deletes the given Storable object
     
     - parameter entity: The Storable object to be deleted, the store will delete any object found with same id and type.
     
     - throws: `StoreError.invalidEntity` if no Storable object with same `id` was found
     */
    public func delete<T: Storable>(_ entity: T) throws {
        let deleted: Bool = barrierSync {
            guard let index = self.lookup(T.self).value.index(where: { $0.id == entity.id }) else {
                return false
            }

            self.lookup(T.self).value.remove(at: index)
            
            return true
        }
        
        if !deleted {
            throw StoreError.invalidEntity
        }
    }
    
    /**
     Find all the objects in the store of a given Storable Type
     
     - parameter (unnamed): The Storable Type to be found
     
     - returns: An array containing the found Storable objects
     */
    public func findAll<T: Storable>(_: T.Type) -> [T] {
        return sync {
            self.lookup(T.self).value.flatMap {$0 as? T}
        }
    }
    
    /**
     Filter all the objects in the store of a given Storable Type that satisfy the a given handler
     
     - parameter (unnamed): The Storable Type to be filtered
     - parameter isIncluded: The predicate to satisfy the filtering
     
     - returns: An array containing the filtered Storable objects
     */
    public func filter<T: Storable>(_: T.Type, isIncluded: (T) -> Bool) -> [T] {
        return findAll(T.self).filter(isIncluded)
    }
    
    /**
     Find the object in the store by a given id
     
     - parameter (unnamed): The Storable Type to be filtered
     - parameter id: The id to search for
     
     - returns: An optional, which may (or may not) contain the found Storable object
     */
    public func find<T: Storable>(_: T.Type, id: String) -> T? {
        return filter(T.self) { $0.id == id }.first
    }
    
    private func generateUUID() -> String {
        uuid += 1
        return String(uuid)
    }
    
    private func lookup<T: Storable>(_: T.Type) -> ArrayBox<Storable> {
        var boxedArray: ArrayBox<Storable>
        
        if let storedBoxedArray = store[String(describing: T.self)] {
            boxedArray = storedBoxedArray
        } else {
            boxedArray = ArrayBox<Storable>([])
            store[String(describing: T.self)] = boxedArray
        }
        
        return boxedArray
    }
}
