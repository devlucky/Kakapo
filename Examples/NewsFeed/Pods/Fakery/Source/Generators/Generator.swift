import Foundation

open class Generator {

  public struct Constants {
    public static let uppercaseLetters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ".characters)
    public static let letters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".characters)
    public static let numbers = Array("0123456789".characters)
  }

  let parser: Parser
  let dateFormatter: DateFormatter

  public required init(parser: Parser) {
    self.parser = parser

    dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
  }

  open func generate(_ key: String) -> String {
    return parser.fetch(key)
  }

  // MARK: - Filling

  open func numerify(_ string: String) -> String {
    let count = UInt32(Constants.numbers.count)

    return String(string.characters.enumerated().map {
      (index, item) in
      let numberIndex = index == 0 ? arc4random_uniform(count - 1) :
        arc4random_uniform(count)
      let char = Constants.numbers[Int(numberIndex)]
      return String(item) == "#" ? char : item
      })
  }

  open func letterify(_ string: String) -> String {
    return String(string.characters.enumerated().map {
      (index, item) in
      let count = UInt32(Constants.uppercaseLetters.count)
      let char = Constants.uppercaseLetters[Int(arc4random_uniform(count))]
      return String(item) == "?" ? char : item
      })
  }

  open func bothify(_ string: String) -> String {
    return letterify(numerify(string))
  }

  open func alphaNumerify(_ string: String) -> String {
    return string.replacingOccurrences(of: "[^A-Za-z0-9_]",
      with: "",
      options: NSString.CompareOptions.regularExpression,
      range: nil)
  }

  open func randomWordsFromKey(_ key: String) -> String {
    var string = ""

    var list = [String]()
    if let wordsList = parser.fetchRaw(key)?.arrayObject {
      for words in wordsList {
        if let item = (words as! [String]).random() {
          list.append(item)
        }
      }

      string = list.joined(separator: " ")
    }

    return string
  }
}
