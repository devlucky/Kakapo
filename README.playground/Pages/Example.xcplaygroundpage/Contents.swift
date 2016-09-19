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
kakapo.serialize() // ["name" : "Kakapo"]

/*:
 All properties are recursively serialized when needed. Only primitive types, arrays, dictionaries and strings are allowed to be converted to json so other types must also be `Serializable`
 */
struct Zoo: Serializable {
    let parrots: [Parrot]
}

let zoo = Zoo(parrots: [kakapo])
zoo.serialize() // ["parrots" : [["name" : "Kakapo"]]]
//: ## Router
let router = Router.register("https://kakapo.com/api")

// handlers with wildcards
router.get("zoo/:animal") { (request) -> Serializable? in
    if request.components["animal"] == "parrot" {
        return Parrot(name: "Kakapo")
    }
    
    return Response(statusCode: 404, body: ["error": "🙁"])
}

//: request **GET** `https://kakapo.com/api/zoo/parrot`
//: will return `{"name": "Kakapo"}`

//: ## KakapoDB
let db = KakapoDB()

struct Author: Storable, Serializable {
    let id: String
    let name: String
    
    // required by Storable
    init(id: String, db: KakapoDB) {
        self.id = id
        self.name = String(arc4random())
    }
}

struct Article: Storable, Serializable {
    let id: String
    let text: String
    let author: Author
    
    init(id: String, db: KakapoDB) {
        self.id = id
        self.text = String(arc4random())
        self.author = db.insert { (id) -> Author in
            return Author(id: id, db: db)
        }
    }
}

//: Create 10 random article
db.create(Article.self, number: 10)
//: Get all articles
router.get("articles") { (request) -> Serializable? in
    return db.findAll(Article.self)
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

// put, del requests...
