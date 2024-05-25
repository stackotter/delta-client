/// A sprite in the GUI texture palette.
public enum GUISprite {
  case heartOutline
  case fullHeart
  case halfHeart
  case foodOutline
  case fullFood
  case halfFood
  case armorOutline
  case fullArmor
  case halfArmor
  case crossHair
  case hotbar
  case selectedHotbarSlot
  case xpBarBackground
  case xpBarForeground
  case inventory

  /// The descriptor for the sprite.
  public var descriptor: GUISpriteDescriptor {
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
      case .armorOutline:
        return .icon(0, 1)
      case .fullArmor:
        return .icon(2, 1)
      case .halfArmor:
        return .icon(1, 1)
      case .crossHair:
        return GUISpriteDescriptor(slice: .icons, position: [3, 3], size: [9, 9])
      case .hotbar:
        return GUISpriteDescriptor(slice: .widgets, position: [0, 0], size: [182, 22])
      case .selectedHotbarSlot:
        return GUISpriteDescriptor(slice: .widgets, position: [0, 22], size: [24, 24])
      case .xpBarBackground:
        return GUISpriteDescriptor(slice: .icons, position: [0, 64], size: [182, 5])
      case .xpBarForeground:
        return GUISpriteDescriptor(slice: .icons, position: [0, 69], size: [182, 5])
      case .inventory:
        return GUISpriteDescriptor(slice: .inventory, position: [0, 0], size: [176, 166])
    }
  }
}
