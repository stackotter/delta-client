import Foundation

/// A Java compatible linear conguential generator.
///
/// For the same seed, this RNG generates the exact same sequence as Java java.util.Random.
/// Based on the specification at https://docs.oracle.com/javase/6/docs/api/java/util/Random.html and
/// the source code at https://developer.classpath.org/doc/java/util/Random-source.html.
public struct Random {
  public private(set) var seed: Int64

  private static var magic: Int64 = 0x5DEECE66D
  private static var mask: Int64 = (1 << 48) - 1
  private static var addend: Int64 = 0xB

  private var nextNextGaussian: Double = 0
  private var haveNextNextGaussian = false

  public init() {
    self.init(Int64(NSDate().timeIntervalSince1970 * 1000))
  }

  public init(_ seed: Int64) {
    self.seed = Self.scrambleSeed(seed)
  }

  private static func scrambleSeed(_ seed: Int64) -> Int64 {
    return (seed ^ magic) & mask
  }

  private mutating func next(_ bits: Int64) -> Int32 {
    seed = (seed &* Self.magic &+ Self.addend) & Self.mask
    return Int32(truncatingIfNeeded: seed >>> (48 &- bits))
  }

  public mutating func setSeed(_ seed: Int64) {
    self.seed = Self.scrambleSeed(seed)
    haveNextNextGaussian = false
  }

  public mutating func nextLong() -> Int64 {
    return (Int64(next(32)) << 32) &+ Int64(next(32))
  }

  public mutating func nextInt() -> Int32 {
    return next(32)
  }

  /// Returns a random `Int32` with the given exclusive max.
  public mutating func nextInt(_ max: Int32) -> Int32 {
    var bits: Int32
    var val: Int32
    repeat {
      bits = next(31)
      val = bits % max
    } while (bits &- val &+ (max &- 1) < 0)
    return val
  }

  public mutating func nextBool() -> Bool {
    return next(1) != 0
  }

  public mutating func nextFloat() -> Float {
    return Float(next(24)) / (Float(1 << 24))
  }

  public mutating func nextDouble() -> Double {
    return Double((Int64(next(26)) << 27) &+ Int64(next(27))) / Double(1 << 53)
  }

  public mutating func nextGaussian() -> Double {
    if haveNextNextGaussian {
      haveNextNextGaussian = false
      return nextNextGaussian
    } else {
      var v1: Double
      var v2: Double
      var s: Double
      repeat {
        v1 = 2 * nextDouble() - 1
        v2 = 2 * nextDouble() - 1
        s = v1 * v1 + v2 * v2
      } while s >= 1 || s == 0
      let multiplier = Foundation.sqrt(-2 * Foundation.log(s) / s)
      nextNextGaussian = v2 * multiplier
      haveNextNextGaussian = true
      return v1 * multiplier
    }
  }
}

// MARK: Operators

infix operator >>> : BitwiseShiftPrecedence

// swiftlint:disable:next:private_over_fileprivate
fileprivate func >>> (lhs: Int64, rhs: Int64) -> Int64 {
  return Int64(bitPattern: UInt64(bitPattern: lhs) >> UInt64(rhs))
}
