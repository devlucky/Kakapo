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
- [Features](#features)
- [Introduction](#introduction)
  - [Why Kakapo?](#why-kakapo)
  - [Concepts](#concepts)
  - [How it works?](#how-it-works)
- [Usage](#usage)
  - [Installation](#installation)
  - [Examples](#examples)
- [Components](#components)
  - [KakapoServer](#server)
  - [KakapoDB](#database)
  - [Serializable](#serializable)

## Features

  * Dynamic mocking
  * Intercepting of HTTP methods (GET, POST, DEL, PUT) with custom handling
  * In-memory database
  * Serialization from any type to JSON
  * JSONAPI serialization support
  * Custom key transformers

## Introduction

Kakapo is a dynamic mocking library. It allows you to fully replicate your backend logic and state in a simple manner.

But is much more than that. With Kakapo, you can easily fully prototype your application based on your backend needs.

### Why Kakapo?

Explain here the usual way to statically mock stuff

### Concepts

  * Registering a router and intercepting methods
  * Using the database
  * Serializable and custom Serializable

### How it works?

Kakapo is made with a easy-to-use design in mind. To get started, you can just create a simple Router that intercepts some GET calls like this:

```Swift
let router = Router.register("http://www.test.com")
router.get("/users/:id"){ request in
  return { "id" : 2 }
}
```

Now, where is the dynamic part you might ask? Here is when the different components of Kakapo take part:

```Swift
let db = KakapoDB()
db.create(UserFactory.self, number: 20)

router.get("/users/:id"){ request in
  return db.find(UserFactory.self, id: Int(request.components["id"]!)!)
}
```

Now, we've created 20 random Users and mocked our request to return the one that matches the id from the request. Yes, *that easy*.

## Usage

### Installation


### Examples


## Components


### KakapoServer


### KakapoDB


### Serializable
