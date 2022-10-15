import Foundation

public enum ClientboundPacketError: LocalizedError {
  case invalidDifficulty
  case invalidGamemode
  case invalidServerId
  case invalidJSONString
  case invalidInventorySlotCount(Int)
  case invalidInventorySlotIndex(Int, windowId: Int)
  case invalidChangeGameStateReasonRawValue(ChangeGameStatePacket.Reason.RawValue)
  case invalidDimension(Identifier)
  
  public var errorDescription: String? {
    switch self {
      case .invalidDifficulty:
        return "Invalid difficulty."
      case .invalidGamemode:
        return "Invalid gamemode."
      case .invalidServerId:
        return "Invalid server Id."
      case .invalidJSONString:
        return "Invalid JSON string."
      case .invalidInventorySlotCount(let slotCount):
        return """
        Invalid inventory slot count.
        Slot count: \(slotCount)
        """
      case .invalidInventorySlotIndex(let slotIndex, let windowId):
        return """
        Invalid inventory slot index.
        Slot index: \(slotIndex)
        Window Id: \(windowId)
        """
      case .invalidChangeGameStateReasonRawValue(let rawValue):
        return """
        Invalid change game state reason.
        Raw value: \(rawValue)
        """
      case .invalidDimension(let identifier):
        return """
        Invalid dimension.
        Identifier: \(identifier)
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
