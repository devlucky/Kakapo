import Foundation
import Kakapo // NOTE: Build "Kakapo iOS" for a 64 bit simulator to successfully import the dynamic framework

// playgrounds are not supported in Swift 2.3, please use 3.0 branch (ATM WIP)
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
let json = NSString(data: zoo.toData()!, encoding: NSUTF8StringEncoding)!

//: ## CustomSerializable
struct CustomZoo: CustomSerializable {
    let parrots: [Parrot]
    
    // this is a really simple `CustomSerializable` that could be achieved with `Serializable` by just using a property "species" (dictionary). 
    // See JSONAPI implementation for more complex, real life, examples.
    func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
        // transformer will be not nill when this object is wrapped into a `SerializationTransformer` (e.g. `SnakeCaseTransformer`)... if the object doesn't need key transformation just ignore it
        let key: (String) -> (String) = { (key) in
            return keyTransformer?(key: key) ?? key
        }
        
        let species = [key("parrot"): parrots.serialize() ?? []]
        return [key("species"): species]
    }
}

let customZoo = CustomZoo(parrots: [kakapo])
let customZooJson = NSString(data: customZoo.toData()!, encoding: NSUTF8StringEncoding)!

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
let personJson = NSString(data: serializable.toData()!, encoding: NSUTF8StringEncoding)!

//: ## Router
let router = Router.register("https://kakapo.com/api/v1")
router.get("zoo/:animal") { (request) -> Serializable? in
    if let animal = request.components["animal"] where animal == "parrot" {
        return Parrot(name: "Kakapo") // or use KakapoDB for dynamic stuff!
    }
    return Response(statusCode: 404, body: ["error": "Animal not found"])
}

//: request **GET** `https://kakapo.com/api/v1/parrot`
//: will return `{"name": "Kakapo"}`

//: ## KakapoDB
let db = KakapoDB()

struct Author: Storable, Serializable {
    let id: String
    let name: String
    
    init(id: String, db: KakapoDB) {
        self.id = id
        self.name = String(arc4random()) // use Fakery!
    }
}

struct Article: Storable, Serializable {
    let id: String
    let text: String
    let author: Author
    
    init(id: String, db: KakapoDB) {
        self.id = id
        self.text = String(arc4random()) // use Fakery!
        author = db.insert { (id) -> Author in
            return Author(id: id, db: db) // id must always come from db
        }
    }
}

//: Create 10 random article
let articles = db.create(Article.self, number: 10)
//: Get all articles
router.get("articles") { (request) -> Serializable? in
    return db.findAll(Article)
}

//: Get all articles from the given author
router.get("articles/:author_id") { (request) -> Serializable? in
    return db.filter(Article.self) { (article) -> Bool in
        return article.author.id == request.components["author_id"]
    }
}

//: Create an article
router.post("article") { (request) -> Serializable? in
    return db.insert { (id) -> Article in
        return Article(id: id, db: db)
    }
}
