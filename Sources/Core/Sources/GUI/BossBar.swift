import Foundation

public struct BossBar {
  public var id: UUID
  public var title: ChatComponent
  /// The boss's health as a value from 0 to 1.
  public var health: Float
  public var color: Color
  public var style: Style
  public var flags: Flags

  public enum Color: Int {
    case pink = 0
    case blue = 1
    case red = 2
    case green = 3
    case yellow = 4
    case purple = 5
    case white = 6

    /// The background and foreground sprites used when rendering a boss bar of
    /// this color.
    public var sprites: (background: GUISprite, foreground: GUISprite) {
      switch self {
        case .pink:
          return (.pinkBossBarBackground, .pinkBossBarForeground)
        case .blue:
          return (.blueBossBarBackground, .blueBossBarForeground)
        case .red:
          return (.redBossBarBackground, .redBossBarForeground)
        case .green:
          return (.greenBossBarBackground, .greenBossBarForeground)
        case .yellow:
          return (.yellowBossBarBackground, .yellowBossBarForeground)
        case .purple:
          return (.purpleBossBarBackground, .purpleBossBarForeground)
        case .white:
          return (.whiteBossBarBackground, .whiteBossBarForeground)
      }
    }
  }

  public enum Style: Int {
    case noNotches = 0
    case sixNotches = 1
    case tenNotches = 2
    case twelveNotches = 3
    case twentyNotches = 4

    /// The bar overlay sprite used when rendering a boss bar of this style.
    public var overlay: GUISprite {
      switch self {
        case .noNotches:
          return .bossBarNoNotchOverlay
        case .sixNotches:
          return .bossBarSixNotchOverlay
        case .tenNotches:
          return .bossBarTenNotchOverlay
        case .twelveNotches:
          return .bossBarTwelveNotchOverlay
        case .twentyNotches:
          return .bossBarTwentyNotchOverlay
      }
    }
  }

  public struct Flags {
    public var darkenSky: Bool
    public var createFog: Bool
    public var isEnderDragonHealthBar: Bool

    public init(darkenSky: Bool, createFog: Bool, isEnderDragonHealthBar: Bool) {
      self.darkenSky = darkenSky
      self.createFog = createFog
      self.isEnderDragonHealthBar = isEnderDragonHealthBar
    }
  }

  public init(
    id: UUID,
    title: ChatComponent,
    health: Float,
    color: BossBar.Color,
    style: BossBar.Style,
    flags: BossBar.Flags
  ) {
    self.id = id
    self.title = title
    self.health = health
    self.color = color
    self.style = style
    self.flags = flags
  }
}
