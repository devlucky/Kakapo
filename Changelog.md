# Changelog

### HEAD
--------------

- Swift 3.0 Support
- Renamed `HTTPBody` to `httpBody` and `HTTPHeader` to `httpHeader`
- `HTTPMethod` enum cases are now lowercase
- Update APIs to follow Swift 3 new naming guidelines

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
