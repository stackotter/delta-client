import Foundation

public struct TeleportConfirmPacket: ServerboundPacket {
  public static let id: Int = 0x00
  
  public var teleportId: Int
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(Int32(teleportId))
  }
}
