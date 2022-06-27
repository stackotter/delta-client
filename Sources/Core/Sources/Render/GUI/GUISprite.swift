/// A sprite in the GUI texture palette.
enum GUISprite {
  case heartOutline
  case fullHeart
  case halfHeart
  case foodOutline
  case fullFood
  case halfFood
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
      case .foodOutline:
        return .icon(0, 3)
      case .fullFood:
        return .icon(4, 3)
      case .halfFood:
        return .icon(5, 3)
      case .crossHair:
        return GUISpriteDescriptor(slice: .icons, position: [3, 3], size: [9, 9])
    }
  }
}
