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
 All properties are recursively serialized when needed. Only primitive types, arrays, dictionaries and strings are allowed to be converted to json so other types must also be `Serializable`
 */
struct Zoo: Serializable {
    let parrots: [Parrot]
}

let zoo = Zoo(parrots: [kakapo])
zoo.serialized() // ["parrots" : [["name" : "Kakapo"]]]
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

//: ## Store
let store = Store()

struct Author: Storable, Serializable {
    let id: String
    let name: String
    
    // required by Storable
    init(id: String, store: Store) {
        self.id = id
        self.name = String(arc4random())
    }
}

struct Article: Storable, Serializable {
    let id: String
    let text: String
    let author: Author
    
    init(id: String, store: Store) {
        self.id = id
        self.text = String(arc4random())
        self.author = store.insert { (id) -> Author in
            return Author(id: id, store: store)
        }
    }
}

//: Create 10 random article
store.create(Article.self, number: 10)
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

// put, del requests...
