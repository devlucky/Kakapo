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
kakapo.serialize()

/*:
 All properties are recursively serialized when needed. Only primitive values, arrays, dictionaries and string are allowed to be converted to json so other values must also be `Serializable`
 */
struct Zoo: Serializable {
    let parrots: [Parrot]
}

let zoo = Zoo(parrots: [kakapo])
let json = zoo.prettyPrint()

//: ## CustomSerializable
struct Custom: CustomSerializable {
    func customSerialize(keyTransformer: KeyTransformer?) -> AnyObject? {
         return ["foo": "bar"]
    }
}

let custom = Custom()
let customJson = custom.prettyPrint()

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
let personJson = serializable.prettyPrint()

//: ## Router
let router = Router.register("https://kakapo.com/api/v1")

router.get("zoo/:animal") { (request) -> Serializable? in
    if let animal = request.components["animal"] where animal == "parrot" {
        return Parrot(name: "Kakapo")
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
        self.text = String(arc4random())
        author = db.insert { (id) -> Author in
            return Author(id: id, db: db)
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
