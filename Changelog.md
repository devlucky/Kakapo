# Changelog

### HEAD
--------------

### 2.0.0
-----------

#### Breaking

- ***Swift 3.0 Support***
- Renamed `HTTPBody` to `httpBody` and `HTTPHeader` to `httpHeader`
- `HTTPMethod` enum cases are now lowercase
- Updated APIs to follow Swift 3 new naming guidelines:

  #### Serializable
  - `serialize(_ keyTransformer: KeyTransformer? = nil) -> Any?` -> `serialized(transformingKeys keyTransformer: KeyTransformer? = nil) -> Any?`

  #### CustomSerializable
  - `customSerialize(_ keyTransformer: KeyTransformer?) -> Any?` -> `customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any?`

  #### Store
  - `filter<T: Storable>(_: T.Type, includeElement: (T) -> Bool) -> [T]` -> `filter<T: Storable>(_: T.Type, isIncluded: (T) -> Bool) -> [T]`

  #### JSONAPISerializable
  - `data(includeRelationships: Bool, includeAttributes: Bool, keyTransformer: KeyTransformer?) -> Any?` -> `data(includingRelationships: Bool, includingAttributes: Bool, transformingKeys keyTransformer: KeyTransformer?) -> Any?`
  - `includedRelationships(includeChildren: Bool, keyTransformer: KeyTransformer?) -> [Any]?` -> `includedRelationships(includingChildren: Bool, transformingKeys keyTransformer: KeyTransformer?) -> [Any]?`

  #### JSONAPISerializer
  - `init(_ object: T, topLevelLinks: [String: JSONAPILink]? = nil, topLevelMeta: Serializable? = nil, includeChildren: Bool = false)` -> `init(_ object: T, topLevelLinks: [String: JSONAPILink]? = nil, topLevelMeta: Serializable? = nil, includingChildren: Bool = false)`


### 1.0.1
-----------

- Fix `Router` to handle same url with different HTTP methods

### 1.0.0
------------

- Swift 2.3 support
- Renamed `KakapoDB` to `Store`
- `init(id:db:)` required by `Storable` protocol has been changed to `init(id:store:)`
- Renamed `KakapoServer` to `Server`

### 0.2.0
------------

- Just another Swift 2.2 release before 1.0.0
- Implement `NSURLProtocol.stopLoading()` for delayed requests (#96) by @leviathan
- Prevent empty include array on `JSONAPISerializable arrays when no relationships
- Update excluded link key `topLinks` to `relationshipsLinks`

### 0.1.0
------------

- Initial release 🎉
