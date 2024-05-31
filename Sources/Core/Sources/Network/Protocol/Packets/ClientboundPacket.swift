import Foundation

public enum ClientboundPacketError: LocalizedError {
  case invalidDifficulty
  case invalidGamemode(rawValue: Int8)
  case invalidServerId
  case invalidJSONString
  case invalidInventorySlotCount(Int)
  case invalidInventorySlotIndex(Int, windowId: Int)
  case invalidChangeGameStateReasonRawValue(ChangeGameStatePacket.Reason.RawValue)
  case invalidDimension(Identifier)
  case invalidBossBarActionId(Int)
  case invalidBossBarColorId(Int)
  case invalidBossBarStyleId(Int)
  case duplicateBossBar(UUID)
  case noSuchBossBar(UUID)

  public var errorDescription: String? {
    switch self {
      case .invalidDifficulty:
        return "Invalid difficulty."
      case let .invalidGamemode(rawValue):
        return """
        Invalid gamemode.
        Raw value: \(rawValue)
        """
      case .invalidServerId:
        return "Invalid server Id."
      case .invalidJSONString:
        return "Invalid JSON string."
      case let .invalidInventorySlotCount(slotCount):
        return """
        Invalid inventory slot count.
        Slot count: \(slotCount)
        """
      case let .invalidInventorySlotIndex(slotIndex, windowId):
        return """
        Invalid inventory slot index.
        Slot index: \(slotIndex)
        Window Id: \(windowId)
        """
      case let .invalidChangeGameStateReasonRawValue(rawValue):
        return """
        Invalid change game state reason.
        Raw value: \(rawValue)
        """
      case let .invalidDimension(identifier):
        return """
        Invalid dimension.
        Identifier: \(identifier)
        """
      case let .invalidBossBarActionId(actionId):
        return """
        Invalid boss bar action id.
        Id: \(actionId)
        """
      case let .invalidBossBarColorId(colorId):
        return """
        Invalid boss bar color id.
        Id: \(colorId)
        """
      case let .invalidBossBarStyleId(styleId):
        return """
        Invalid boss bar style id.
        Id: \(styleId)
        """
      case let .duplicateBossBar(uuid):
        return """
        Received duplicate boss bar.
        UUID: \(uuid.uuidString)
        """
      case let .noSuchBossBar(uuid):
        return """
        Received update for non-existent boss bar.
        UUID: \(uuid)
        """
    }
  }
}

public protocol ClientboundPacket {
  static var id: Int { get }

  init(from packetReader: inout PacketReader) throws
  func handle(for client: Client) throws
  func handle(for pinger: Pinger) throws
}

extension ClientboundPacket {
  public func handle(for client: Client) {
    return
  }

  public func handle(for pinger: Pinger) {
    return
  }
}
