import Foundation

public struct BossBarPacket: ClientboundPacket {
  public static let id: Int = 0x0c
  
  public var uuid: UUID
  public var action: BossBarAction

  
  public enum BossBarAction {
    case add(title: ChatComponent, health: Float, color: BossBar.Color, style: BossBar.Style, flags: BossBar.Flags)
    case remove
    case updateHealth(health: Float)
    case updateTitle(title: ChatComponent)
    case updateStyle(color: BossBar.Color, style:BossBar.Style)
    case updateFlags(flags: BossBar.Flags)
  }
  
  public init(from packetReader: inout PacketReader) throws {
    uuid = try packetReader.readUUID()
    let actionId = try packetReader.readVarInt()
    switch actionId {
      case 0:
        let title = try packetReader.readChat()
        let health = try packetReader.readFloat()
        let color = try Self.readColor(from: &packetReader)
        let style = try Self.readStyle(from: &packetReader)
        let flags = try Self.readFlags(from: &packetReader)
        action = .add(title: title, health: health, color: color, style: style, flags: flags)
      case 1:
        action = .remove
      case 2:
        let health = try packetReader.readFloat()
        action = .updateHealth(health: health)
      case 3:
        let title = try packetReader.readChat()
        action = .updateTitle(title: title)
      case 4:
        let color = try Self.readColor(from: &packetReader)
        let style = try Self.readStyle(from: &packetReader)
        action = .updateStyle(color: color, style: style)
      case 5:
        let flags = try Self.readFlags(from: &packetReader)
        action = .updateFlags(flags: flags)
      default:
        throw ClientboundPacketError.invalidBossBarActionId(actionId)
    }
  }

  public static func readColor(from packetReader: inout PacketReader) throws -> BossBar.Color {
    let colorId = try packetReader.readVarInt()
    guard let color = BossBar.Color(rawValue: colorId) else {
      throw ClientboundPacketError.invalidBossBarColorId(colorId)
    }
    return color
  }

  public static func readStyle(from packetReader: inout PacketReader) throws -> BossBar.Style {
    let styleId = try packetReader.readVarInt()
    guard let style = BossBar.Style(rawValue: styleId) else {
      throw ClientboundPacketError.invalidBossBarStyleId(styleId)
    }
    return style
  }

  public static func readFlags(from packetReader: inout PacketReader) throws -> BossBar.Flags {
    let bitField = try packetReader.readUnsignedByte()
    return BossBar.Flags(
      darkenSky: bitField & 1 == 1,
      createFog: bitField & 4 == 4,
      isEnderDragonHealthBar: bitField & 2 == 2
    )
  }

  public func handle(for client: Client) throws {
    try client.game.mutateGUIState { guiState in
      for (i, var bar) in guiState.bossBars.enumerated() where bar.id == uuid {
        switch action {
          case .remove:
            guiState.bossBars.remove(at: i)
            return
          case let .updateHealth(health):
            bar.health = health
          case let .updateTitle(title):
            bar.title = title
          case let .updateStyle(color, style):
            bar.color = color
            bar.style = style
          case let .updateFlags(flags):
            bar.flags = flags
          case .add:
            throw ClientboundPacketError.duplicateBossBar(uuid)
        }
        guiState.bossBars[i] = bar
        return
      }

      switch action {
        case let .add(title, health, color, style, flags):
          guiState.bossBars.append(
            BossBar(
              id: uuid,
              title: title,
              health: health,
              color: color,
              style: style,
              flags: flags
            )
          )
        default:
          throw ClientboundPacketError.noSuchBossBar(uuid)
      }
    }
  }
}
