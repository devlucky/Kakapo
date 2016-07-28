import Foundation

public class Lorem: Generator {

  public func word() -> String {
    return generate("lorem.words")
  }

  public func words(amount amount: Int = 3) -> String {

    var words: [String] = []
    for _ in 0..<amount {
      words.append(word())
    }

    return words.joinWithSeparator(" ")
  }

  public func character() -> String {
    return characters(amount: 1)
  }

  public func characters(amount amount: Int = 255) -> String {
    var chars = ""

    if amount > 0 {
      for _ in 0..<amount {
        let char = Character(UnicodeScalar(arc4random() % (122-97) + 97))
        chars.append(char)
      }
    }

    return chars
  }

  public func sentence(wordsAmount wordsAmount: Int = 4) -> String {
    var sentence = words(amount: wordsAmount) + "."
    sentence.replaceRange(sentence.startIndex...sentence.startIndex, with: String(sentence[sentence.startIndex]).capitalizedString)
    return sentence
  }

  public func sentences(amount amount: Int = 3) -> String {
    return (0..<amount).reduce("") { (text, _) -> String in
        return text + sentence()
    }
  }

  public func paragraph(sentencesAmount sentencesAmount: Int = 3) -> String {
    return sentences(amount: sentencesAmount)
  }

  public func paragraphs(amount amount: Int = 3) -> String {
    return (0..<amount).reduce("") { (text, _) -> String in
        return text + paragraph()
    }
  }
}
