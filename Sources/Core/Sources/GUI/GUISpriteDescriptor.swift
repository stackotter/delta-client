import FirebladeMath

/// Describes how to render a specific sprite from a ``GUITexturePalette``.
public struct GUISpriteDescriptor {
  /// The slice containing the sprite.
  public var slice: GUITextureSlice
  /// The position of the sprite in the texture. Origin is at the top left.
  public var position: Vec2i
  /// The size of the sprite.
  public var size: Vec2i

  /// Creates the descriptor for the specified icon. Icons start 16 pixels from the left of the
  /// texture and are arranged as a grid of 9x9 icons.
  /// - Parameters:
  ///   - xIndex: The horizontal index of the sprite.
  ///   - yIndex: The vertical index of the sprite.
  /// - Returns: A sprite descriptor for the icon.
  public static func icon(_ xIndex: Int, _ yIndex: Int) -> GUISpriteDescriptor {
    return GUISpriteDescriptor(
      slice: .icons,
      position: [xIndex * 9 + 16, yIndex * 9],
      size: [9, 9]
    )
  }
}
