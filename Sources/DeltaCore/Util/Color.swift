import Foundation
import simd

public struct Color {
  /// The int vector
  public var vector: SIMD3<Int>
  
  /// A float vector containing the rgb representation of the colour.
  public var floatVector: SIMD3<Float> {
    return SIMD3<Float>(vector)
  }
  
  /// The red component of the color.
  public var r: Int {
    return vector.x
  }
  
  /// The green component of the color.
  public var g: Int {
    return vector.y
  }
  
  /// The blue component of the color.
  public var b: Int {
    return vector.z
  }
  
  /// Creates a color from rgb components.
  public init(r: Int, g: Int, b: Int) {
    vector = [r, g, b]
  }
  
  /// Creates a color from a 3 byte hex code's integer representation.
  public init(hexCode: Int) {
    let r = (hexCode >> 16)
    let g = (hexCode >> 8) & 0xf
    let b = hexCode & 0xf
    vector = [r, g, b]
  }
}
