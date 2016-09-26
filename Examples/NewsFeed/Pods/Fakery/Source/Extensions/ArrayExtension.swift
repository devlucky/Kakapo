import Foundation

extension Array {

  func at(_ index: Int?) -> Element? {
    if let index = index , index >= 0 && index < endIndex {
      return self[index]
    } else {
      return nil
    }
  }

  func random() -> Element? {
    var object: Element?

    if count > 0 {
      object = self[Int(arc4random_uniform(UInt32(count)))]
    }

    return object
  }
}
