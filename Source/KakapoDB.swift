//
//  KakapoDB.swift
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
    /// The unique identifier provided by `KakapoDB`, objects shouldn't generate ids themselves. `KakapoDB` generate `Int` ids converted to String for better compatibilities with standards like JSONAPI, in case you need `Int` ids is safe to assume that the conversion will always succeeed.
    var id: String { get }
    
    /**
     An initializer that is used by `KakapoDB` to create objects to be stored in the db
     
     - parameter id: The unique identifier provided by `KakapoDB`, objects shouldn't generate ids themselves. `KakapoDB` generate `Int` ids converted to String for better compatibilities with standards like JSONAPI, in case you need `Int` ids is safe to ssume that the conversion will always succeeed.
     - parameter db: The db that is creating the object, can be used  to generate other `Storable` objects, for example relationships of the object: `myRelationship = db.create(MyRelationshipType)` or `myrelationship = db.insert { MyRelationshipType(id: $0, db: db) }`. The relationsip will also recieve the `db` instance to eventually initialize its relationships.
     
     - returns: A configured object stored in the db.
     */
    init(id: String, db: KakapoDB)
}

enum KakapoDBError: ErrorType {
    case InvalidEntity
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

/**
 An in-memory database that holds state supporting insertion, deletion, updating and finding.
 
 You can use this class together with a Router to achieve the behavior you want after some request is done. An example
 could be returning an User after a get request with that User's id:
 
    let db = KakapoDB()
    db.create(User.self, number: 20)
 
    router.get("/users/:id"){ request in
        return db.find(User.self, id: someId)
    }
 
 In order for your classes to be used by the database, they must conform to the `Storable` protocol. For more info about `Router` and `Serializable`, check the `Router` class documentation.
 */
public final class KakapoDB {
    
    private let queue = dispatch_queue_create("com.kakapodb.queue", DISPATCH_QUEUE_CONCURRENT)
    private var _uuid = -1
    private var store: [String: ArrayBox<Storable>] = [:]

    /// Initialize a new in-memory database
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

    private func sync<T>(closure: () -> T) -> T {
        var object: T?
        dispatch_sync(queue) {
            object = closure()
        }
        return object!
    }
    
    /**
     Creates and inserts Storable objects based on their default initializer
     
     - parameter (unnamed): The Storable Type to be created
     - parameter number: The number of elements to create, defaults to 1
     
     - returns: An array containing the new inserted Storable objects
     */
    public func create<T: Storable>(_: T.Type, number: Int = 1) -> [T] {
        let ids = barrierSync {
            return (0..<number).map { _ in self.uuid()}
        }
        
        let objects = ids.map { id in T(id: id, db: self) }
        
        barrierAsync {
            self.lookup(T).value.appendContentsOf(objects.flatMap{ $0 as Storable })
        }
        
        return objects
    }
    
    /**
     Creates an inserts an Storable object returned by a given handler
     
     - parameter handler: A handler that will be called with a new `id` and will return the new Storable element to be inserted. The `id` needs to be used when creating the new Storable element, otherwise this method will assert.
     
     - returns: The new inserted Storable object
     */
    public func insert<T: Storable>(handler: (String) -> T) -> T {
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
    
    /**
     Updates the given Storable object
     
     - parameter entity: The Storable object to be updated
     
     - throws: `KakapoDBError.InvalidEntity` if no Storable object with same `id` was found
     */
    public func update<T: Storable>(entity: T) throws {
        let updated: Bool = barrierSync {
            let index = self.lookup(T).value.indexOf { $0.id == entity.id }
            guard let indexToUpdate = index else { return false }
            self.lookup(T).value[indexToUpdate] = entity
            
            return true
        }
        
        if !updated {
            throw KakapoDBError.InvalidEntity
        }
    }
    
    /**
     Deletes the given Storable object
     
     - parameter entity: The Storable object to be deleted, the database will delete any object found with same id and type.
     
     - throws: `KakapoDBError.InvalidEntity` if no Storable object with same `id` was found
     */
    public func delete<T: Storable>(entity: T) throws {
        let deleted: Bool = barrierSync {
            guard let index = self.lookup(T).value.indexOf({ $0.id == entity.id }) else {
                return false
            }

            self.lookup(T).value.removeAtIndex(index)
            
            return true
        }
        
        if !deleted {
            throw KakapoDBError.InvalidEntity
        }
    }
    
    /**
     Find all the objects in the store of a given Storable Type
     
     - parameter (unnamed): The Storable Type to be found
     
     - returns: An array containing the found Storable objects
     */
    public func findAll<T: Storable>(_: T.Type) -> [T] {
        return sync {
            self.lookup(T).value.flatMap{$0 as? T}
        }
    }
    
    /**
     Filter all the objects in the store of a given Storable Type that satisfy the a given handler
     
     - parameter (unnamed): The Storable Type to be filtered
     - parameter includeElement: The predicate to satisfy the filtering
     
     - returns: An array containing the filtered Storable objects
     */
    public func filter<T: Storable>(_: T.Type, includeElement: (T) -> Bool) -> [T] {
        return findAll(T).filter(includeElement)
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
    
    private func uuid() -> String {
        _uuid += 1
        return String(_uuid)
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
