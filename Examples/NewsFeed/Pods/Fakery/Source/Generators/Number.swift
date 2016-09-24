import Foundation
import CoreGraphics

open class Number {

  fileprivate var lastUsedId: Int64 = 0

  open func randomBool() -> Bool {
    return randomInt() % 2 == 0
  }

  open func randomInt(min: Int = 0, max: Int = 1000) -> Int {
    return min + Int(arc4random_uniform(UInt32(max - min + 1)))
  }

  open func randomFloat(min: Float = 0, max: Float = 1000) -> Float {
    return (Float(arc4random()) / Float(UInt32.max)) * (max - min) + min
  }

  open func randomCGFloat(min: CGFloat = 0, max: CGFloat = 1000) -> CGFloat {
    return CGFloat(Float(arc4random()) / Float(UInt32.max)) * (max - min) + min
  }

  open func randomDouble(min: Double = 0, max: Double = 1000) -> Double {
    return (Double(arc4random()) / Double(UInt32.max)) * (max - min) + min
  }

  open func increasingUniqueId() -> Int {
    OSAtomicIncrement64(&lastUsedId)
    return Int(lastUsedId)
  }
}
