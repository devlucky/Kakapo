import Foundation

open class Internet: Generator {

  let lorem: Lorem

  public required init(parser: Parser) {
    self.lorem = Lorem(parser: parser)
    super.init(parser: parser)
  }

  open func username(separator: String? = nil) -> String {
    var components: [String] = [
      generate("name.first_name"),
      generate("name.last_name"),
      "\(arc4random_uniform(10000))"
    ]

    let randomCount = UInt32(components.count) - 1
    let count = Int(arc4random_uniform(randomCount) + randomCount)

    var gap = ""
    if let sep = separator {
      gap = sep
    }

    return components[0..<count].joined(separator: gap).replacingOccurrences(of: "'", with: "").lowercased()
  }

  open func domainName(_ alphaNumericOnly: Bool = true) -> String {
    return domainWord(alphaNumericOnly: alphaNumericOnly) + "." + domainSuffix()
  }

  open func domainWord(alphaNumericOnly: Bool = true) -> String {
    let nameParts = generate("company.name").components(separatedBy: " ")
    var name = ""
    if let first = nameParts.first {
      name = first
    } else {
      name = letterify("?????")
    }

    let result = alphaNumericOnly ? alphaNumerify(name) : name
    return result.lowercased()
  }

  open func domainSuffix() -> String {
    return generate("internet.domain_suffix")
  }

  open func email() -> String {
    return [username(), domainName()].joined(separator: "@")
  }

  open func freeEmail() -> String {

    return [username(), generate("internet.free_email")].joined(separator: "@")
  }

  open func safeEmail() -> String {
    let topLevelDomains = ["org", "com", "net"]
    let count = UInt32(topLevelDomains.count)
    let topLevelDomain = topLevelDomains[Int(arc4random_uniform(count))]

    return [username(), "example." + topLevelDomain].joined(separator: "@")
  }

  open func password(minimumLength: Int = 8, maximumLength: Int = 16) -> String {
    var temp = lorem.characters(amount: minimumLength)
    let diffLength = maximumLength - minimumLength
    if diffLength > 0 {
      let diffRandom = Int(arc4random_uniform(UInt32(diffLength + 1)))
      temp += lorem.characters(amount: diffRandom)
    }
    return temp
  }

  open func ipV4Address() -> String {
    let ipRand = {
      2 + arc4random() % 253
    }

    return String(format: "%d.%d.%d.%d", ipRand(), ipRand(), ipRand(), ipRand())
  }

  open func ipV6Address() -> String {
    var components: [String] = []

    for _ in 1..<8 {
      components.append(String(format: "%X", arc4random() % 65535))
    }

    return components.joined(separator: ":")
  }

  open func url() -> String {
    return "http://\(domainName())/\(username())"
  }

  open func image(width: Int = 320, height: Int = 200) -> String {
    return "http://lorempixel.com/\(width)/\(height)"
  }

  open func templateImage(width: Int = 320, height: Int = 200,
    backColorHex: String = "000000", frontColorHex: String = "ffffff") -> String {
      return "http://dummyimage.com/\(width)x\(height)/\(backColorHex)/\(frontColorHex)"
  }

  // @ToDo - slug
}
