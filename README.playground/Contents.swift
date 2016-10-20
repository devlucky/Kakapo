import Foundation
import Kakapo

/*:
 # Kakapo
 
 ## Serializable
 Serializable objects are mirrored to be converted to a `Dictionary`
 */
struct Parrot: Serializable {
    let name: String
}

let kakapo = Parrot(name: "Kakapo")
kakapo.serialized() // ["name" : "Kakapo"]

/*:
 All properties are recursively serialized when needed. Only primitive values, arrays, dictionaries and string are allowed to be converted to json so other values must also be `Serializable`
 */
struct Zoo: Serializable {
    let parrots: [Parrot]
}

let zoo = Zoo(parrots: [kakapo])
zoo.serialized() // ["parrots" : [["name" : "Kakapo"]]]
let json = String(data: zoo.toData()!, encoding: .utf8)!
//: ## Router
let router = Router.register("https://kakapo.com/api/v1")
// handlers with wildcards
router.get("zoo/:animal") { (request) -> Serializable? in
    if let animal = request.components["animal"], animal == "parrot" {
        return Parrot(name: "Kakapo")
    }
    
    return Response(
        statusCode: 404,
        body: ["error": "Animal not found"]
    )
}

//: request **GET** `https://kakapo.com/api/v1/parrot`
//: will return `{"name": "Kakapo"}`

//: ## Store
let store = Store()

struct Author: Storable, Serializable {
    let id: String
    let firstName: String
    
    init(id: String, store: Store) {
        self.id = id
        self.firstName = String(arc4random()) // use Fakery!
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
            return Author(id: id, store: store)
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


//: ## CustomSerializable
struct CustomZoo: CustomSerializable {
    let parrots: [Parrot]
    
    func customSerialized(transformingKeys keyTransformer: KeyTransformer?) -> Any? {
        let species = ["parrot": parrots.serialized() ?? []]
        return ["species": species]
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

let dog = Dog(id: "2", name: "Joan")
let person = Person(id: "1", name: "Alex", dog: dog)
let serializable = JSONAPISerializer(person,
                                     topLevelMeta: ["foo": "bar"])
let personJson = String(data: serializable.toData()!, encoding: .utf8)!

//: ## SerializationTransformer
let authors = store.findAll(Author.self)
let snakes = SnakecaseTransformer(authors).serialized()

struct UppercaseTransformer<T: Serializable>: SerializationTransformer {
    
    let wrapped: T
    
    init(_ wrapped: T) {
        self.wrapped = wrapped
    }
    
    func transform(key: String) -> String {
        return key.uppercased()
    }
}

let bigAuthors = UppercaseTransformer(authors).serialized()
//: `SerializationTransformer`s can also be composed
let bigSnakes = UppercaseTransformer(SnakecaseTransformer(authors)).serialized()


//: ## Expanding Optional properties
//: nil won't be included in the JSON
Optional<Int>.none.serialized()

Optional<Int>.some(2).serialized()

PropertyPolicy<Int>.none.serialized()

PropertyPolicy<Int>.some(2).serialized()
//: NSNull, will be included in the JSON
PropertyPolicy<Int>.null.serialized()

