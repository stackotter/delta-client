import Foundation

/// An error thrown by ``GUITexturePalette``.
public enum GUITexturePaletteError: Error {
  case missingSlice(GUITextureSlice)
}

/// A palette of GUI textures.
public struct GUITexturePalette {
  /// The palette of GUI textures.
  public private(set) var palette: TexturePalette
  /// Slice indices indexed by ``GUITextureSlice/rawValue``.
  private var sliceIndices: [Int]

  /// Creates a typesafe GUI texture palette from a regular texture palette.
  public init(_ texturePalette: TexturePalette) throws {
    palette = texturePalette
    sliceIndices = [Int](repeating: -1, count: GUITextureSlice.allCases.count)
    for slice in GUITextureSlice.allCases {
      if let index = texturePalette.identifierToIndex[slice.identifier] {
        sliceIndices[slice.rawValue] = index
      } else {
        throw GUITexturePaletteError.missingSlice(slice)
      }
    }
  }

  /// Gets the texture index for the specified slice.
  /// - Parameter slice: The slice to get.
  /// - Returns: The texture index.
  public func textureIndex(for slice: GUITextureSlice) -> Int {
    return sliceIndices[slice.rawValue]
  }
}
