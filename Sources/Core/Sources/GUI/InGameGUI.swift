import SwiftCPUDetect

public class InGameGUI {
  // TODO: Figure out why anything greater than 252 breaks the protocol. Anything less than 256 should work afaict
  public static let maximumMessageLength = 252

  /// The number of seconds until messages should be hidden from the regular GUI.
  static let messageHideDelay: Double = 10
  /// The maximum number of messages displayed in the regular GUI.
  static let maximumDisplayedMessages = 10
  /// The width of the chat history.
  static let chatHistoryWidth = 330

  /// The system's CPU display name.
  static let cpuName = HWInfo.CPU.name()
  /// The system's CPU architecture.
  static let cpuArch = CpuArchitecture.current()?.rawValue
  /// The system's total memory.
  static let totalMem = (HWInfo.ramAmount() ?? 0) / (1024 * 1024 * 1024)
  /// A string containing information about the system's default GPU.
  static let gpuInfo = GPUDetection.mainMetalGPU()?.infoString()

  static let xpLevelTextColor = Vec4f(126, 252, 31, 255) / 255

  public init() {}

  public func content(game: Game, state: GUIStateStorage) -> GUIElement {
    let gamemode = game.accessPlayer(acquireLock: false) { player in
      player.gamemode.gamemode
    }

    return GUIElement.stack {
      GUIElement.sprite(.crossHair)
        .center()

      if gamemode != .spectator {
        hotbarArea(game: game, gamemode: gamemode)
      }
    }
  }

  /// The hotbar (and nearby stats if in a gamemode with health).
  public func hotbarArea(game: Game, gamemode: Gamemode) -> GUIElement {
    var health: Float = 0
    var food: Int = 0
    var selectedSlot: Int = 0
    var xpBarProgress: Float = 0
    var xpLevel: Int = 0
    var hotbarSlots: [Slot] = []
    game.accessPlayer(acquireLock: false) { player in
      health = player.health.health
      food = player.nutrition.food
      selectedSlot = player.inventory.selectedHotbarSlot
      xpBarProgress = player.experience.experienceBarProgress
      xpLevel = player.experience.experienceLevel
      hotbarSlots = player.inventory.hotbar
    }

    return GUIElement.list(spacing: 0) {
      if gamemode.hasHealth {
        stats(health: health, food: food, xpBarProgress: xpBarProgress, xpLevel: xpLevel)
      }

      hotbar(slots: hotbarSlots, selectedSlot: selectedSlot)
    }
      .size(GUISprite.hotbar.descriptor.size.x + 2, nil)
      .constraints(.bottom(-1), .center)
  }

  public func hotbar(slots: [Slot], selectedSlot: Int) -> GUIElement {
    GUIElement.stack {
      GUIElement.sprite(.hotbar)
        .padding(1)
      GUIElement.sprite(.selectedHotbarSlot)
        .positionInParent(selectedSlot * 20, 0)

      GUIElement.forEach(in: slots, direction: .horizontal, spacing: 4) { slot in
        inventorySlot(slot)
      }
        .positionInParent(4, 4)
    }
  }

  public func inventorySlot(_ slot: Slot) -> GUIElement {
    // TODO: Make if blocks layout transparent (their children should be treated as children of the parent block)
    if let stack = slot.stack {
      return GUIElement.stack {
        GUIElement.item(id: stack.itemId)

        textWithShadow("\(stack.count)", shadowColor: Vec4f(62, 62, 62, 255) / 255)
          .constraints(.bottom(-2), .right(-1))
          .float()
      }
        .size(16, 16)
    } else {
      return GUIElement.spacer(width: 16, height: 16)
    }
  }

  public func textWithShadow(
    _ text: String,
    textColor: Vec4f = Vec4f(1, 1, 1, 1),
    shadowColor: Vec4f
  ) -> GUIElement {
    GUIElement.stack {
      GUIElement.text(text, color: shadowColor)
        .positionInParent(1, 1)
      GUIElement.text(text, color: textColor)
    }
  }

  public enum ReadingDirection {
    case leftToRight
    case rightToLeft
  }

  public func stats(
    health: Float,
    food: Int,
    xpBarProgress: Float,
    xpLevel: Int
  ) -> GUIElement {
    GUIElement.list(spacing: 0) {
      GUIElement.stack {
        discreteMeter(
          Int(health.rounded()),
          fullIcon: .fullHeart,
          halfIcon: .halfHeart,
          outlineIcon: .heartOutline
        )

        discreteMeter(
          food,
          fullIcon: .fullFood,
          halfIcon: .halfFood,
          outlineIcon: .foodOutline,
          direction: .rightToLeft
        )
          .constraints(.top(0), .right(0))
      }
        .size(GUISprite.hotbar.descriptor.size.x, nil)
        .constraints(.top(0), .center)

      GUIElement.stack {
        continuousMeter(
          xpBarProgress,
          background: .xpBarBackground,
          foreground: .xpBarForeground
        )
          .constraints(.top(0), .center)

        outlinedText("\(xpLevel)", textColor: Self.xpLevelTextColor)
          .constraints(.top(-7), .center)
      }
        .padding(1)
        .constraints(.top(0), .center)
    }
  }

  public func outlinedText(
    _ text: String,
    textColor: Vec4f,
    outlineColor: Vec4f = Vec4f(0, 0, 0, 1)
  ) -> GUIElement {
    let outlineText = GUIElement.text(text, color: outlineColor)
    return GUIElement.stack {
      outlineText.constraints(.top(0), .left(1))
      outlineText.constraints(.top(1), .left(0))
      outlineText.constraints(.top(1), .left(2))
      outlineText.constraints(.top(2), .left(1))
      GUIElement.text(text, color: textColor)
        .constraints(.top(1), .left(1))
    }
  }

  public func discreteMeter(
    _ value: Int,
    fullIcon: GUISprite,
    halfIcon: GUISprite,
    outlineIcon: GUISprite,
    direction: ReadingDirection = .leftToRight
  ) -> GUIElement {
    let fullIconCount = value / 2
    let hasHalfIcon = value % 2 == 0
    var range = Array(0..<10)
    if direction == .rightToLeft {
      range = range.reversed()
    }
    return GUIElement.forEach(in: range, direction: .horizontal, spacing: -1) { i in
      GUIElement.stack {
        GUIElement.sprite(outlineIcon)
        if i < fullIconCount {
          GUIElement.sprite(fullIcon)
        } else if hasHalfIcon && i == fullIconCount {
          GUIElement.sprite(halfIcon)
        }
      }
    }
  }

  public func continuousMeter(
    _ value: Float,
    background: GUISprite,
    foreground:GUISprite
  ) -> GUIElement {
    var croppedForeground = foreground.descriptor
    croppedForeground.size.x = Int(Float(croppedForeground.size.x) * value)
    return GUIElement.stack {
      GUIElement.sprite(background)
      GUIElement.customSprite(croppedForeground)
    }
  }
}
