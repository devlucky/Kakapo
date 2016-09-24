import Foundation
import Kakapo // NOTE: Build "Kakapo iOS" for a 64 bit simulator to successfully import the dynamic framework

/*:
 # Kakapo
 
 ## Serializable
 Serializable objects are mirrored to be converted to a `Dictionary`
 */
struct Parrot: Serializable {
    let name: String
}

let kakapo = Parrot(name: "Kakapo")
kakapo.serialize()

/*:
 All properties are recursively serialized when needed. Only primitive values, arrays, dictionaries and string are allowed to be converted to json so other values must also be `Serializable`
 */
struct Zoo: Serializable {
    let parrots: [Parrot]
}

let zoo = Zoo(parrots: [kakapo])
let json = String(data: zoo.toData()!, encoding: .utf8)!

//: ## CustomSerializable
struct CustomZoo: CustomSerializable {
    let parrots: [Parrot]
    
    // this is a really simple `CustomSerializable` that could be achieved with `Serializable` by just using a property "species" (dictionary). 
    // See JSONAPI implementation for more complex, real life, examples.
    func customSerialize(_ keyTransformer: KeyTransformer?) -> Any? {
        // transformer will be not nill when this object is wrapped into a `SerializationTransformer` (e.g. `SnakeCaseTransformer`)... if the object doesn't need key transformation just ignore it
        let key: (String) -> (String) = { (key) in
            return keyTransformer?(key) ?? key
        }
        
        let species = [key("parrot"): parrots.serialize() ?? []]
        return [key("species"): species]
    }
}

let customZoo = CustomZoo(parrots: [kakapo])
let customZooJson = String(data: customZoo.toData()!, encoding: .utf8)!

//: ## JSON API
struct Dog: JSONAPIEntity {
    let id: String
    let name: String
}

struct Person: JSONAPIEntity {
    let id: String
    let name: String
    let dog: Dog
}

let person = Person(id: "1", name: "Alex", dog: Dog(id: "2", name: "Joan"))
let serializable = JSONAPISerializer(person, topLevelMeta: ["foo": "bar"])
let personJson = String(data: serializable.toData()!, encoding: .utf8)!

//: ## Router
let router = Router.register("https://kakapo.com/api/v1")
router.get("zoo/:animal") { (request) -> Serializable? in
    if let animal = request.components["animal"], animal == "parrot" {
        return Parrot(name: "Kakapo") // or use Store for dynamic stuff!
    }
    return Response(statusCode: 404, body: ["error": "Animal not found"])
}

//: request **GET** `https://kakapo.com/api/v1/parrot`
//: will return `{"name": "Kakapo"}`

//: ## Store
let store = Store()

struct Author: Storable, Serializable {
    let id: String
    let name: String
    
    init(id: String, store: Store) {
        self.id = id
        self.name = String(arc4random()) // use Fakery!
    }
}

struct Article: Storable, Serializable {
    let id: String
    let text: String
    let author: Author
    
    init(id: String, store: Store) {
        self.id = id
        self.text = String(arc4random()) // use Fakery!
        author = store.insert { (id) -> Author in
            return Author(id: id, store: store) // id must always come from the store
        }
    }
}

//: Create 10 random article
let articles = store.create(Article.self, number: 10)
//: Get all articles
router.get("articles") { (request) -> Serializable? in
    return store.findAll(Article.self)
}

//: Get all articles from the given author
router.get("articles/:author_id") { (request) -> Serializable? in
    return store.filter(Article.self) { (article) -> Bool in
        return article.author.id == request.components["author_id"]
    }
}

//: Create an article
router.post("article") { (request) -> Serializable? in
    return store.insert { (id) -> Article in
        return Article(id: id, store: store)
    }
}
