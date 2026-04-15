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
  case craftingTable
  case furnace
  case blastFurnace
  case smoker
  case anvil
  case dispenser
  case beacon

  /// If positioned directly above ``GUISprite/genericInventory`` it forms
  /// the background for a single chest window. The way the texture is made forces
  /// these to be separate sprites.
  case genericInventory // Inventory for most interfaces, its a part of the sprite
  case generic9x1
  case generic9x2
  case generic9x3
  case generic9x4
  case generic9x5
  case generic9x6

  case pinkBossBarBackground
  case pinkBossBarForeground
  case blueBossBarBackground
  case blueBossBarForeground
  case redBossBarBackground
  case redBossBarForeground
  case greenBossBarBackground
  case greenBossBarForeground
  case yellowBossBarBackground
  case yellowBossBarForeground
  case purpleBossBarBackground
  case purpleBossBarForeground
  case whiteBossBarBackground
  case whiteBossBarForeground

  case bossBarNoNotchOverlay
  case bossBarSixNotchOverlay
  case bossBarTenNotchOverlay
  case bossBarTwelveNotchOverlay
  case bossBarTwentyNotchOverlay

  /// The sprite for a connection strength in the range `0...5`.
  case playerConnectionStrength(PlayerInfo.ConnectionStrength)

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
      case .craftingTable:
        return GUISpriteDescriptor(slice: .craftingTable, position: [0, 0], size: [176, 166])
      case .furnace:
        return GUISpriteDescriptor(slice: .furnace, position: [0, 0], size: [176, 166])
      case .blastFurnace:
        return GUISpriteDescriptor(slice: .blastFurnace, position: [0, 0], size: [176, 166])
      case .smoker:
        return GUISpriteDescriptor(slice: .smoker, position: [0, 0], size: [176, 166])
      case .anvil:
        return GUISpriteDescriptor(slice: .anvil, position: [0, 0], size: [176, 166])
      case .dispenser:
        return GUISpriteDescriptor(slice: .dispenser, position: [0, 0],  size: [176, 166])
      case .beacon:
        return GUISpriteDescriptor(slice: .beacon, position: [0,0], size: [229, 218])
      case .genericInventory:
        return GUISpriteDescriptor(slice: .genericContainer, position: [0, 125], size: [176, 97])
      case .generic9x1:
        return GUISpriteDescriptor(slice: .genericContainer, position: [0, 0], size: [176, 35])
      case .generic9x2:
        return GUISpriteDescriptor(slice: .genericContainer, position: [0, 0], size: [176, 53])
      case .generic9x3:
        return GUISpriteDescriptor(slice: .genericContainer, position: [0, 0], size: [176, 71])
      case .generic9x4:
        return GUISpriteDescriptor(slice: .genericContainer, position: [0, 0], size: [176, 89])
      case .generic9x5:
        return GUISpriteDescriptor(slice: .genericContainer, position: [0, 0], size: [176, 107])
      case .generic9x6:
        return GUISpriteDescriptor(slice: .genericContainer, position: [0, 0], size: [176, 222])
      case .pinkBossBarBackground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 0], size: [182, 5])
      case .pinkBossBarForeground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 5], size: [182, 5])
      case .blueBossBarBackground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 10], size: [182, 5])
      case .blueBossBarForeground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 15], size: [182, 5])
      case .redBossBarBackground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 20], size: [182, 5])
      case .redBossBarForeground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 25], size: [182, 5])
      case .greenBossBarBackground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 30], size: [182, 5])
      case .greenBossBarForeground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 35], size: [182, 5])
      case .yellowBossBarBackground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 40], size: [182, 5])
      case .yellowBossBarForeground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 45], size: [182, 5])
      case .purpleBossBarBackground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 50], size: [182, 5])
      case .purpleBossBarForeground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 55], size: [182, 5])
      case .whiteBossBarBackground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 60], size: [182, 5])
      case .whiteBossBarForeground:
        return GUISpriteDescriptor(slice: .bars, position: [0, 65], size: [182, 5])
      case .bossBarNoNotchOverlay:
        return GUISpriteDescriptor(slice: .bars, position: [0, 70], size: [182, 5])
      case .bossBarSixNotchOverlay:
        return GUISpriteDescriptor(slice: .bars, position: [0, 80], size: [182, 5])
      case .bossBarTenNotchOverlay:
        return GUISpriteDescriptor(slice: .bars, position: [0, 90], size: [182, 5])
      case .bossBarTwelveNotchOverlay:
        return GUISpriteDescriptor(slice: .bars, position: [0, 100], size: [182, 5])
      case .bossBarTwentyNotchOverlay:
        return GUISpriteDescriptor(slice: .bars, position: [0, 110], size: [182, 5])
      case let .playerConnectionStrength(strength):
        let y = 16 + (5 - strength.rawValue) * 8
        return GUISpriteDescriptor(slice: .icons, position: [0, y], size: [10, 7])
    }
  }
}
