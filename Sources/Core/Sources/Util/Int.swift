import Foundation

extension Int {
  /// Whether the integer is a positive power of two or not.
  public var isPowerOfTwo: Bool {
    return (self > 0) && (self & (self - 1) == 0)
  }

  /// The integer as hex (including the `0x` prefix).
  public var hexWithPrefix: String {
    "0x" + hex
  }

  /// The integer as hex (without any prefix).
  public var hex: String {
    String(self, radix: 16)
  }
}
