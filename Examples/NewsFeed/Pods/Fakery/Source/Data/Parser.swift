import SwiftyJSON

open class Parser {

  open var locale: String {
    didSet {
      if locale != oldValue {
        loadData()
      }
    }
  }

  var data: JSON = []
  var provider: Provider

  public init(locale: String = Config.defaultLocale) {
    self.provider = Provider()
    self.locale = locale
    loadData()
  }

  // MARK: - Parsing

  open func fetch(_ key: String) -> String {
    var parsed = ""

    if let keyData = fetchRaw(key) {
      let subject = getSubject(key)

      if let value = keyData.string {
        parsed = value
      } else if let array = keyData.arrayObject {
        if let item = array.random() as? String {
          parsed = item
        }
      }

      if parsed.range(of: "#{") != nil {
        parsed = parse(parsed, forSubject: subject)
      }
    }

    return parsed
  }

  open func fetchRaw(_ key: String) -> JSON? {
    var keyData: JSON?
    let parts = key.components(separatedBy: ".")

    if parts.count > 0 {
      var parsed = data[locale]["faker"]

      for part in parts {
        parsed = parsed[part]
      }

      keyData = parsed
    }

    return keyData
  }

  func parse(_ template: String, forSubject subject: String) -> String {
    var text = ""
    let string = template as NSString
    var regex: NSRegularExpression
    do {
      try regex = NSRegularExpression(pattern: "(\\(?)#\\{([A-Za-z]+\\.)?([^\\}]+)\\}([^#]+)?", options: .caseInsensitive)
      let matches = regex.matches(in: string as String,
                                  options: .reportCompletion,
                                  range: NSRange(location: 0, length: string.length))

      if matches.count > 0 {
        for match in matches {
          if match.numberOfRanges < 4 {
            continue
          }

          let prefixRange = match.rangeAt(1)
          let subjectRange = match.rangeAt(2)
          let methodRange = match.rangeAt(3)
          let otherRange = match.rangeAt(4)

          if prefixRange.length > 0 {
            text += string.substring(with: prefixRange)
          }

          var subjectWithDot = subject + "."
          if subjectRange.length > 0 {
            subjectWithDot = string.substring(with: subjectRange)
          }

          if methodRange.length > 0 {
            let key = subjectWithDot.lowercased() + string.substring(with: methodRange)
            text += fetch(key)
          }

          if otherRange.length > 0 {
            text += string.substring(with: otherRange)
          }
        }
      } else {
        text = template
      }
    } catch {}


    return text
  }

  func getSubject(_ key: String) -> String {
    var subject: String = ""
    var parts = key.components(separatedBy: ".")

    if parts.count > 0 {
      subject = parts[0]
    }

    return subject
  }

  // MARK: - Data loading

  func loadData() {
    if let localeData = provider.dataForLocale(locale) {
      data = JSON(data: localeData,
        options: JSONSerialization.ReadingOptions.allowFragments,
        error: nil)
    } else if locale != Config.defaultLocale {
      locale = Config.defaultLocale
    } else {
      fatalError("JSON file for '\(locale)' locale was not found.")
    }
  }
}
