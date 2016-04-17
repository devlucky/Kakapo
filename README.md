#Kakapo ![partyparrot](http://cultofthepartyparrot.com/sirocco.gif)
[![Language: Swift](https://img.shields.io/badge/lang-Swift-yellow.svg?style=flat)](https://developer.apple.com/swift/)
[![Build Status](https://travis-ci.org/devlucky/Kakapo.svg?branch=master)](https://travis-ci.org/devlucky/Kakapo)
[![Version](https://img.shields.io/cocoapods/v/Kakapo.svg?style=flat)](http://cocoapods.org/pods/Kakapo)
[![CocoaPods](https://img.shields.io/cocoapods/metrics/doc-percent/Kakapo.svg)]()
[![codecov.io](https://codecov.io/github/devlucky/Kakapo/coverage.svg?branch=master)](https://codecov.io/github/devlucky/Kakapo?branch=master)
[![License](https://img.shields.io/cocoapods/l/Kakapo.svg?style=flat)](http://cocoapods.org/pods/Kakapo)
[![Platform](https://img.shields.io/cocoapods/p/Kakapo.svg?style=flat)](http://cocoapods.org/pods/Kakapo)

> Next generation mocking library in Swift

Kakapo aims to cover all needs you, as a mobile developer usualy face while trying to **mock server responses**, it gives you a set of **components** and **conventions** that will solve the most important challenges for HTTP mocking.

It was mainly designed with **JSON-Api** support on mind and medium/big complex Api's, when Kakapo becomes particularly useful to cover advanced and consistent **response payloads** that has a **long life state**, usualy in memory and might be also serialized on demand, especially when working with **not ready Api's** that has a expected and common behaviour.

The DSL allows you to define a **client-side-server** in which you can define your routes exactly as in the real one, having totally control of the request, status code, dynamic paths and query params. Also Kakapo brings you an **in memory database** which essentially gives you the ability of create, read, update and delete records. This records are defined in an expresive way thanks to **KakapoFactories** and are able to handle **model relationships** and **fake data** generation withing other features, this records are serialized using the **KakapoSerializers**, which are build in a idiomatic way. Finally you have the chance of create different **database scenarios** and use it when you want.

## Contents
- [Features](#features)
- [Introduction](#introduction)
  - [Why Kakapo?](#why-kakapo)
  - [Concepts](#concepts)
  - [How it works?](#how-it-works)
- [Usage](#usage)
  - [Installation](#installation)
  - [Examples](#examples)
- [Components](#components)
  - [Server](#server)
  - [Router](#router)
  - [Database](#database)
  - [Factories](#factories)
  - [Scenarios](#scenarios)
  - [Serializers](#serializers)
  - [Fake Data](#fake-data)


## Features

- Full-featured mocking DSL library built on the top of **generics** and **protocols**
- Advanced route handling
- Hackable and elegant programmatic API
- Featured built-in router with custom response handling
- **CRUD support** out of the box
- **JSON-Api** first
- Hierarchical and composable 
- Supports all common HTTP abstrations (Status code, body, headers...)
- **TDD support** by default + extendable scenarios
- Easily to extend with custom components per entity
- Built-in Serializers
- Able to run in **different environments** (test, development, hight performance cases...)
- Stateful database with convinience methods 

## Introduction


### Why Kakapo?


### Concepts


### How it works?


## Usage

```swift
struct User: KakapoFactory {
 let name = Kakapo.name.firstName
 let profileImg = Kakapo.image.avatar
 let friends = Kakapo.random(['paco', 'pepe']) 
}

struct Comment: KakapoFactory {
 let text = Kakapo.lorem(50)
 let user = Kakapo.belongsTo(User)
}

struct Post: KakapoFactory {
 let likes = 10
 let comments = Kakapo.hasMany(Comment)
}

db.create(User, 5)
db.create(Comment, 15)
db.create(Post, 2)

let server = KakapoServer(db)

server.get("/user/:id") { (db, request) in
 return JSONApiSerializer(
  db.find(User, request.params.id)
 )
}
```

### Installation


### Examples


## Components

TODO

### Router

TODO

### Database

TODO

### Factories

TODO

### Scenarios

TODO

### Fake Data

TODO
