import Foundation
import FirebladeMath

/// An RGB color, each component is 1 byte (maximum of 255).
public struct RGBColor: Codable {
  public static var white = RGBColor(r: 255, g: 255, b: 255)
  public static var black = RGBColor(r: 0, g: 0, b: 0)

  /// The int vector
  public var vector: Vec3i

  /// A float vector containing the rgb representation of the colour.
  public var floatVector: Vec3f {
    return Vec3f(vector) / 255
  }

  /// The integer representation of the hexcode of this color. 1 byte per component.
  public var hexCode: Int {
    return (r << 16) | (g << 8) | b
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
  ///
  /// Each component should be between 0 and 255 inclusive.
  public init(r: Int, g: Int, b: Int) {
    vector = [r, g, b]
  }

  /// Creates a color from a 3 byte hex code's integer representation.
  public init(hexCode: Int) {
    let r = (hexCode >> 16) & 0xff
    let g = (hexCode >> 8) & 0xff
    let b = hexCode & 0xff
    vector = [r, g, b]
  }
}
