import Foundation

extension Int {
  public var isPowerOfTwo: Bool {
    return (self > 0) && (self & (self - 1) == 0)
  }
}
