/// A descriptor containing information required to use or render a character from an atlas texture.
public struct CharacterDescriptor {
  /// The texture containing the character.
  public var texture: Int
  /// The x coordinate of the character in the atlas.
  public var x: Int
  /// The y coordinate of the character in the atlas.
  public var y: Int
  /// The width of the character in the atlas.
  public var width: Int
  /// The height of the character in the atlas.
  public var height: Int
  /// The vertical offset that the character should be offset by when rendering.
  public var verticalOffset: Int
  /// A scaling factor to use when rendering the character.
  public var scalingFactor: Float

  /// The width multiplied by the scaling factor (and rounded).
  public var renderedWidth: Int {
    return Int(Float(width) * scalingFactor)
  }
  /// The height multiplied by the scaling factor (and rounded).
  public var renderedHeight: Int {
    return Int(Float(height) * scalingFactor)
  }
}
