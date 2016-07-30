#Kakapo ![partyparrot](http://cultofthepartyparrot.com/sirocco.gif)
[![Language: Swift](https://img.shields.io/badge/lang-Swift-yellow.svg?style=flat)](https://developer.apple.com/swift/)
[![Build Status](https://travis-ci.org/devlucky/Kakapo.svg?branch=master)](https://travis-ci.org/devlucky/Kakapo)
[![Version](https://img.shields.io/cocoapods/v/Kakapo.svg?style=flat)](http://cocoapods.org/pods/Kakapo)
[![DocCov](https://img.shields.io/cocoapods/metrics/doc-percent/Kakapo.svg)](http://cocoadocs.org/docsets/Kakapo)
[![codecov](https://codecov.io/gh/devlucky/Kakapo/branch/master/graph/badge.svg)](https://codecov.io/gh/devlucky/Kakapo)
[![codebeat badge](https://codebeat.co/badges/69a42ece-740c-4a29-b25a-598deaf61fca)](https://codebeat.co/projects/github-com-devlucky-kakapo)
[![License](https://img.shields.io/cocoapods/l/Kakapo.svg?style=flat)](http://cocoapods.org/pods/Kakapo)
[![Platform](https://img.shields.io/cocoapods/p/Kakapo.svg?style=flat)](http://cocoapods.org/pods/Kakapo)

> Next generation mocking library in Swift

Kakapo **dynamically mocks server responses**.

## Contents
- [Why Kakapo?](#why-kakapo)
- [Features](#features)
- [Setup/Installation](#setup/installation)
- [Usage](#usage)
  - [Serializable protocol](#serializable-protocol)
  - [Router: registering and intercepting methods](#router---registering-and-intercepting-methods)
  - [Leverage the database - Dynamic mocking](#leverage-the-database---dynamic-mocking)
  - [CustomSerializable](#customserializable)
  - [JSONAPI](#jsonapi)
  - [Expanding Null values with Property Policy](#expanding-null-values-with-property-policy)
  - [Key customization - Serialization Transformer](#key-customization---serialization-transformer)
  - [Full responses on ResponseFieldsProvider](full-responses-on-responsefieldsprovider)
- [Examples](#examples)
- [Roadmap](#roadmap)
- [Authors](#authors)

Kakapo is a dynamic mocking library. It allows you to fully replicate your backend logic and state in a simple manner.

But is much more than that. With Kakapo, you can easily fully prototype your application based on your backend needs.

## Why Kakapo?

A common approach when testing network requests is to stub them with fake network data from local files. This has some well known disadvantages:

- Data which does not reflect the actual behavior from backend.
- Static files with fake responses which need to be updated every time APIs are updated.
- Mock data which is just **dumb** data.
- Boilerplate code and additional files needed to setup stubbed local files.

While still this approach may work good, Kakapo will be a game changer in your network tests: it will give you complete control when it comes to simulating backend behavior completely. Moreover, you can even take a step further and prototype your application before having a real service behind!

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

## Setup/Installation

Using [CocoaPods](http://cocoapods.org/):

```ruby
use_frameworks!
pod 'Kakapo'
```

## Usage

Kakapo is made with an easy-to-use design in mind. To quickly get started, you can create a simple Router that intercepts GET requests like this:

```Swift
let router = Router.register("http://www.test.com")
router.get("/users"){ request in
  return ["id" : 2]
}
```

You might be wondering where the dynamic part is; here is when the different modules of Kakapo take place:

```Swift
let db = KakapoDB()
db.create(User.self, number: 20)

router.get("/users"){ request in
  return db.findAll(User.self)
}
```

Now, we've created 20 random `User` objects and mocked our request to return them. Yes, it's *that easy*.

Let's get a closer look to the different modules:

### Serializable protocol

Kakapo uses the `Serializable` protocol in order to serialize objects in JSON format. *Any type* can be serialized as long as it conforms to this protocol:

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

### Router - registering and intercepting methods

As you may have noticed, Kakapo uses Routers in order to keep track of the registered endpoints that are to be intercepted.

You can match *any* relative path from the registered base URL that you want, as long as your components are properly represented. This means that wildcard components will need to be represented with colon:

```Swift
let router = Router.register("http://www.test.com")

// Will match http://www.test.com/users/28
router.get("/users/:id") { ... }

// Will match http://www.test.com/users/28/comments/123
router.get("/users/:id/comments/:comment_id") { ... }
```

The handler argument also needs to return the Serializable object that will be used once the URL is matched.

```Swift
let router = Router.register("http://www.test.com")

router.get("/users/:id") { request in
  return ["user" : foo]
}

router.get("/users/:id/comments/:comment_id") { request in
  return ["comment" : bar]
}
```

After this, everything is ready to test your mocked objects; you can perform your normal requests as always:

```Swift
session.dataTaskWithURL(NSURL(string: "http://www.test.com/users/1")!) { (data, _, _) in
  let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
  // responseDictionary == { "user" : foo }
}.resume()

session.dataTaskWithURL(NSURL(string: "http://www.test.com/users/1/comments/2")!) { (data, _, _) in
  let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
  // responseDictionary == { "comment" : bar }
}.resume()
```

Note that previous registrations will also be compatible with same URLs which have query parameters:

```Swift
// Will also be matched since we previously registered "/users/:id/comments/:comment_id"
session.dataTaskWithURL(NSURL(string: "http://www.test.com/users/1/comments/2?page=2&author=hector")!) { (data, _, _) in
  let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
  // responseDictionary == { "comment" : bar }
}.resume()
```

Remember that, instead of a plain dictionary, you can return whatever object you want as long as it is Serializable:

```Swift
struct User: Storable, Serializable {
    let firstName: String
    let lastName: String
    let age: Int
}

router.get("/users/:id") { request in
  return User(firstName: "Alex", lastName: "Culone", age: 28)
}
```

When registering paths, the RouteHandler passes a Request object that fully represents your request. Thus, you can make use of them in order to pass specific objects.

This may be useful, for instance, when you want to get a specific user based on a given id URL component:

```Swift
router.get("/users/:id"){ request in
  let userId = request.components["id"] // userId = 2
  let user = findUserWithId(userId)
  return ["foo" : user]
}

session.dataTaskWithURL(NSURL(string: "http://www.test.com/users/2")!) { (_, _, _) in
}.resume()
```

### Leverage the database - Dynamic mocking

But Kakapo gets even more powerful when using your Routers together with the Database. This way, you can define own types and insert, remove, update or find them.

This lets you mock any behavior you want after a request is made, as if it was a real backend. In other words, this brings you **dynamic** mocking.

In order for them to be used by the Database, your types need to conform to the `Storable` protocol.

```Swift
struct User: Storable, Serializable {
    let firstName: String
    let lastName: String
    let age: Int
    let id: Int

    init(id: Int, db: KakapoDB) {
        self.init(firstName: randomString(), lastName: randomString(), age: random(), id: id)
    }
}
```

An example usage could be returning an User after a get request with that user's id:

```Swift
let db = KakapoDB()
db.create(User.self, number: 20)

router.get("/users/:id"){ request in
  let userId = request.components["id"]
  return db.find(User.self, id: userId)
}
```

But, of course, you could perform any logic which fits your needs:

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

  return [:]
}
```

### CustomSerializable

In [Serializable](#serializable-protocol) we described how your classes can be serialized. The serialization mechanism, by default, will basically mirror your object's properties and recursively serialize them into JSON.

Whenever a different behavior is needed, you can instead conform to CustomSerializable in order to provide your custom serialization. The serialization mechanism will check whether your object is CustomSerializable before proceeding with normal serialization.

For instance, Array uses CustomSerializable to return an Array with its serialized objects inside. Dictionary, on the other hand, is serialized by creating a Dictionary with the same keys and serialized values.

Besides foundation classes, Kakapo makes use of CustomSerializable in order to bring full JSONAPI serialization.

### JSONAPI

Since Kakapo was built with JSONAPI support in mind, a JSONAPISerializer is therefore provided to mock APIs with this concrete specification.

For your types to be JSONAPI compliant, they need to conform to `JSONAPIEntity` protocol, a CustomSerializable subprotocol. Let's see an example:

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

Note that `JSONAPIEntity` objects are already `Serializable` and you could just use them together with your Routers. However, to completely follow the JSONAPI structure in your responses, we highly encourage to use a `JSONAPISerializer` struct:

```Swift
let cats = [Cat(id: "33", name: "Stancho"), Cat(id: "44", name: "Hez")]
let dog = Dog(id: "22", name: "Joan", cat: cats[0])
let user = User(id: "11", name: "Alex", dog: dog, cats: cats)

router.get("/users/:id"){ request in
  return JSONAPISerializer(user)
}
```

### Expanding Null values with Property Policy

When serializing to JSON, you may want to represent a property value as `null`. For this, you can use the PropertyPolicy enum to represent your properties:

```Swift
public enum PropertyPolicy<Wrapped>: CustomSerializable {
    case None
    case Null
    case Some(Wrapped)
}
```

PropertyPolicy is an enum similar to Optional but with an additional case `.Null`. It's only purpose is to be serialized in 3 different ways to cover all possible behaviors of an Optional property.

When dealing with PropertyPolicy properties, the serializer will serialize as nil when `.None`, `NSNull` when `.Null` or serialize the object for `.Some`:

```Swift
private struct Test: Serializable {
    let value: PropertyPolicy<Int>
}

let serialized = Test(value: PropertyPolicy<Int>.None).serialize()
print(serialized["value"]) // nil

let serialized = Test(value: PropertyPolicy<Int>.Null).serialize()
print(serialized["value"]) // NSNull

let serialized = Test(value: PropertyPolicy<Int>.Some(1)).serialize()
print(serialized["value"]) // 1
```

### Key customization - Serialization Transformer

One thing to consider when serializing objects is key naming: that is, the serialization mechanism will use by default the property names for the keys in order to build the JSON objects.

To modify this behavior, you can use the SerializationTransformer, a CustomSerializable subprotocol, in order to wrap your Serializable objects adding your custom key transformation.

For a concrete implementation, check SnakecaseTransformer: a struct that implements SerializationTransformer to convert keys into snake case:

```Swift
let user = User(userName: "Alex")
let serialized = SnakecaseTransformer(user).serialize()
print(serialized) // [ "user_name" : "Alex" ]
```

### Full responses on ResponseFieldsProvider

Furthermore, if your responses need to specify status code (which will be 200 by default) and/or header fields, you can take advantage of ResponseFieldsProvider, another CustomSerializable subprotocol, to customize your responses.

Kakapo provides a default ResponseFieldsProvider implementation in the Response struct, which you can use to embed your Serializable objects into its body:

```Swift
router.get("/users/:id"){ request in
    return Response(statusCode: 400, body: ["id" : 2], headerFields: ["access_token" : "094850348502"])
}

session.dataTaskWithURL(NSURL(string: "http://www.test.com/users/2")!) { (data, response, _) in
    let allHeaders = response.allHeaderFields
    let statusCode = response.statusCode
    print(allHeaders["access_token"]) // 094850348502
    print(statusCode) // 400
    }.resume()
```

## Examples

### Newsfeed

Make sure you check the [demo app](https://github.com/devlucky/Kakapo/tree/feature/READMEDocumentation/Examples/NewsFeed) we created using Kakapo: a prototyped newsfeed app which lets the user create new posts and like/unlike them.

![](https://raw.githubusercontent.com/devlucky/Kakapo/master/Examples/NewsFeed/newsfeed.png)

## Roadmap

Add missing parts on full JSONAPI support.

## Authors

[@MP0w](https://github.com/MP0w) - [@zzarcon](https://github.com/zzarcon) - [@joanromano](https://github.com/joanromano)
