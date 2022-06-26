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
}
