import Foundation

public struct LockDifficultyPacket: ServerboundPacket {
  public static let id: Int = 0x11
  
  public var locked: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeBool(locked)
  }
}
