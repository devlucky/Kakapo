import Foundation

public class Commerce: Generator {

  public func color() -> String {
    return generate("commerce.color")
  }

  public func department(maximum maximum: Int = 3, fixedAmount: Bool = false) -> String {
    let amount = fixedAmount ? maximum : 1 + Int(arc4random_uniform(UInt32(maximum)))

    let fetchedCategories = categories(amount)
    let count = fetchedCategories.count

    var department = ""
    if count > 1 {
      department = mergeCategories(fetchedCategories)
    } else if count == 1 {
      department = fetchedCategories[0]
    }

    return department
  }

  public func productName() -> String {
    return generate("commerce.product_name.adjective") + " " + generate("commerce.product_name.material") + " " + generate("commerce.product_name.product")
  }

  public func price() -> Double {
    let arc4randoMax:Double = 0x100000000
    return floor(Double((Double(arc4random()) / arc4randoMax) * 100.0) * 100) / 100.0
  }

  // MARK: - Helpers

  func categories(amount: Int) -> [String] {
    var categories: [String] = []
    while categories.count < amount {
      let category = generate("commerce.department")
      if !categories.contains(category) {
        categories.append(category)
      }
    }

    return categories
  }

  func mergeCategories(categories: [String]) -> String {
    let separator = generate("separator")
    let commaSeparated = categories[0..<categories.count - 1].joinWithSeparator(", ")
    
    return commaSeparated + separator + categories.last!
  }
}
