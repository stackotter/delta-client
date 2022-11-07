import Foundation

public struct ColorMap {
  /// The width of the color map.
  public var width: Int
  /// The height of the color map.
  public var height: Int
  /// The pixels of the color map. Indexed by `y * width + x`.
  public var colors: [RGBColor] = []

  /// Creates an empty color map.
  public init() {
    width = 0
    height = 0
  }

  /// Loads the colormap from a file
  /// - Parameter pngFile: The png file containing the colormap texture.
  public init(from pngFile: URL) throws {
    let texture = try Texture(pngFile: pngFile, type: .opaque)
    width = texture.width
    height = texture.height

    for y in 0..<height {
      for x in 0..<width {
        let pixel = texture[x, y]
        colors.append(RGBColor(
          r: Int(pixel.red),
          g: Int(pixel.green),
          b: Int(pixel.blue)
        ))
      }
    }
  }

  /// Get the color at some coordinates.
  /// - Parameters:
  ///   - x: The x coordinate.
  ///   - y: The y coordinate.
  /// - Returns: The color at the given coordinates. Returns nil if the coordinates are out of bounds.
  public func color(atX x: Int, y: Int) -> RGBColor? {
    if x >= width || y >= height || x < 0 || y < 0 {
      return nil
    }

    let index = y * width + x
    return colors[index]
  }
}
