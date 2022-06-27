/// A sprite in the GUI texture palette.
enum GUISprite {
  case heartOutline
  case fullHeart
  case halfHeart

  /// The descriptor for the sprite.
  var descriptor: GUISpriteDescriptor {
    switch self {
      case .heartOutline:
        return .icon(3, 0)
      case .fullHeart:
        return .icon(4, 0)
      case .halfHeart:
        return .icon(5, 0)
    }
  }
}
