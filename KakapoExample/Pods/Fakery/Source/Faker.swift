public class Faker {

  public var locale: String {
    didSet {
      if locale != oldValue {
        parser.locale = locale
      }
    }
  }

  public let address: Address
  public let app: App
  public let business: Business
  public let company: Company
  public let commerce: Commerce
  public let internet: Internet
  public let lorem: Lorem
  public let name: Name
  public let phoneNumber: PhoneNumber
  public let team: Team

  let parser: Parser

  public init(locale: String = Config.defaultLocale) {
    self.locale = locale
    parser = Parser(locale: self.locale)

    address = Address(parser: parser)
    app = App(parser: parser)
    business = Business(parser: parser)
    company = Company(parser: parser)
    commerce = Commerce(parser: parser)
    internet = Internet(parser: parser)
    lorem = Lorem(parser: parser)
    name = Name(parser: parser)
    phoneNumber = PhoneNumber(parser: parser)
    team = Team(parser: parser)
  }
}
