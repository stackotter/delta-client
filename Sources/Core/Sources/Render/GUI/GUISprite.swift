/// A sprite in the GUI texture palette.
enum GUISprite {
  case heartOutline
  case fullHeart
  case halfHeart
  case crossHair

  /// The descriptor for the sprite.
  var descriptor: GUISpriteDescriptor {
    switch self {
      case .heartOutline:
        return .icon(0, 0)
      case .fullHeart:
        return .icon(4, 0)
      case .halfHeart:
        return .icon(5, 0)
      case .crossHair:
        return GUISpriteDescriptor(slice: .icons, position: [3, 3], size: [9, 9])
    }
  }
}
