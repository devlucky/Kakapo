#Kakapo ![partyparrot](http://cultofthepartyparrot.com/sirocco.gif)
[![Language: Swift](https://img.shields.io/badge/lang-Swift-yellow.svg?style=flat)](https://developer.apple.com/swift/)
[![Build Status](https://travis-ci.org/devlucky/Kakapo.svg?branch=master)](https://travis-ci.org/devlucky/Kakapo)
[![Version](https://img.shields.io/cocoapods/v/Kakapo.svg?style=flat)](http://cocoapods.org/pods/Kakapo)
[![DocCov](https://img.shields.io/cocoapods/metrics/doc-percent/Kakapo.svg)](http://cocoadocs.org/docsets/Kakapo)
[![codecov](https://codecov.io/gh/devlucky/Kakapo/branch/master/graph/badge.svg)](https://codecov.io/gh/devlucky/Kakapo)
[![License](https://img.shields.io/cocoapods/l/Kakapo.svg?style=flat)](http://cocoapods.org/pods/Kakapo)
[![Platform](https://img.shields.io/cocoapods/p/Kakapo.svg?style=flat)](http://cocoapods.org/pods/Kakapo)

> Next generation mocking library in Swift

Kakapo **dynamically mocks server responses**.


7 billion people on Earth Fewer than 150 Kakapo

[![http://kakaporecovery.org.nz/donate/](https://photos-4.dropbox.com/t/2/AACYHFZXOoaEMhzWw-ZKHV2NZ_-S5-rmvCs7J89NxODSzA/12/421965471/png/32x32/3/1461862800/0/2/kakapoDonate.png/ENidr7EDGFAgAigC/GEeEeCDaW4HTIYWtBr-ut82sr9RL_VdLeIbR0Q-zpN8?size_mode=3&size=320x240)](http://kakaporecovery.org.nz/donate/)

## Contents
- [Introduction](#introduction)
- [Features](#features)
- [Why Kakapo?](#why-kakapo)
- [Setup](#usage)
  - [Installation](#installation)
  - [Examples](#examples)
- [Usage](#usage)
  - [Serializable protocol](#)
  - [Registering a router and intercepting methods](#)
  - [Using the database](#)
- [Roadmap](#roadmap)
- [License](#license)

## Introduction

  Kakapo is a dynamic mocking library. It allows you to fully replicate your backend logic and state in a simple manner.

  But is much more than that. With Kakapo, you can easily fully prototype your application based on your backend needs.

## Features

  * Dynamic mocking and prototyping
  * Swift 2.3 compatible
  * Thread-safe
  * Compatible with macOS/iOS/watchOS/tvOS
  * Protocol oriented
  * Unit tested (with Quick and Nimble)
  * Fully customizable by defining custom serialization and custom responses
  * Out-of-the-box serialization
  * Out-of-the-box JSONAPI support

## Why Kakapo?

Explain here the usual way to statically mock stuff and why kakapo is better

## Setup

### Installation

Cocoapods, etc

### Examples

Probably move this to the end, after use

## Usage

Kakapo is made with a easy-to-use design in mind. To get started, you can create a simple Router that intercepts GET requests like this:

```Swift
let router = Router.register("http://www.test.com")
router.get("/users"){ request in
  return { "id" : 2 }
}
```

You might be wondering where is the dynamic part: here is when the different components of Kakapo take place:

```Swift
let db = KakapoDB()
db.create(User.self, number: 20)

router.get("/users"){ request in
  return db.findAll(User.self)
}
```

Now, we've created 20 random `User` objects and mocked our request to return them. Yes, it's *that easy*.

Let's get a closer look to the different components:

### Serializable protocol

Kakapo uses the `Serializable` protocol in order to serialize objects. *Any type* can be serialized as long as it conforms to this protocol:

```Swift
struct User: Serializable {
  let name: String
}

let user = User(name: "Alex")
let serializedUser = user.serialize()
print(serializedUser["name"]) // Alex
```

Also, foundation classes are supported out-of-the-box: This means that `Array`, `Dictionary` or `Optional` have custom extensions and can also be serialized:

```Swift
let serializedUserArray = [user].serialize()
print(serializedUserArray.first["name"]) // Alex
let serializedUserDictionary = ["test": user].serialize()
print(serializedUserDictionary["test"]["name"]) // Alex
```

`Routers` use this protocol internally to return a JSON representation of your mocked objects.

### Registering a router and intercepting methods

As you may have noticed, Kakapo uses Routers in order to keep track of the registered endpoints that are to be intercepted.

You can match *any* relative path from the registered base URL that you want, as long as you mark your components with a colon sign.

The handler argument also needs to return the Serializable object that will be used once the URL is matched.

```Swift
let router = Router.register("http://www.test.com")

router.get("/users/:id") { request in
  return { "user" : foo }
}

router.get("/users/:id/comments/:comment_id") { request in
  return { "comment" : bar }
}

NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1")!) { (data, _, _) in
  let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
  // responseDictionary == { "user" : foo }
}.resume()

NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1/comments/2")!) { (data, _, _) in
  let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
  // responseDictionary == { "comment" : bar }
}.resume()
```

Note that previous registrations will also be compatible with same URLs which have query parameters:

```Swift
// Will also be matched since we previously registered "/users/:id/comments/:comment_id"
NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/1/comments/2?page=2&author=hector")!) { (data, _, _) in
  let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
  // responseDictionary == { "comment" : bar }
}.resume()
```

When registering paths, the RouteHandler passes a Request object that fully represents your request. Thus, you can make use of them in order to pass specific objects.

This may be useful, for instance, when you want to get a specific user based on a given id URL component:

```Swift
router.get("/users/:id"){ request in
  let userId = request.components["id"] // userId = 2
  let user = findUserWithId(userId)
  return {"foo" : user}
}

NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.test.com/users/2")!) { (_, _, _) in
}.resume()
```

### Using the database

But Kakapo gets even more powerful when using your Routers together with the Database. This way, you can define own types and insert, remove, update or find them.

This lets you mock any behavior you want after a request is made, as if it was a real backend.

In order for them to be used by the Database, your types need to conform to the `Storable` protocol.

```Swift
struct User: Storable, Serializable, Equatable {
    let firstName: String
    let lastName: String
    let age: Int
    let id: Int

    init(id: Int, db: KakapoDB) {
        self.init(firstName: randomString(), lastName: randomString(), age: random(), id: id)
    }
}
```

An example usage could be returning an User after a get request with that User's id:

```Swift
let db = KakapoDB()
db.create(User.self, number: 20)

router.get("/users/:id"){ request in
  let userId = request.components["id"]
  return db.find(User.self, id: userId)
}
```

But of course, you can could perform any logic that fits your needs:

```Swift
router.put("/users/:id"){ request in
  let insertedUser = db.insert { (id) -> User in
    return User(firstName: "Alex", lastName: "Manzella", age: 28, id: id)
  }

  return insertedUser
}

router.post("/users/:id"){ request in
  let userId = request.components["id"]
  let userToUpdate = db.find(User.self, id: userId)
  // Update user...
  db.update(userToUpdate)

  return userToUpdate
}

router.del("/users/:id"){ request in
  let userId = request.components["id"]
  let userToDelete = db.find(User.self, id: userId)
  db.delete(userToDelete)

  return {}
}
```

### JSONAPI

Since Kakapo was built with JSONAPI support in mind, a JSONAPISerializer is

For your types to be JSONAPI compliant, they need to conform to JSONAPIEntity

```Swift
struct Dog: JSONAPIEntity {
    let id: String
    let name: String
}

struct Cat: JSONAPIEntity {
    let id: String
    let name: String
}

struct User: JSONAPIEntity {
    let id: String
    let name: String
    let dog: Dog
    let cats: [Cat]
}
```

Note that `JSONAPIEntity` objects are already `Serializable` and you could just use them together with your Routers. However, to completely follow the JSONAPI structure in your responses, it is encouraged to use a JSONAPISerializer:

```Swift
let cats = [Cat(id: "33", name: "Stancho"), Cat(id: "44", name: "Hez")]
let dog = Dog(id: "22", name: "Joan", cat: cats[0])
let user = User(id: "11", name: "Alex", dog: dog, cats: cats)

router.get("/users/:id"){ request in
  return JSONAPISerializer(user)
}
```

// Not sure if we should talk here about JSONAPILinks and Error


## Roadmap


## License
