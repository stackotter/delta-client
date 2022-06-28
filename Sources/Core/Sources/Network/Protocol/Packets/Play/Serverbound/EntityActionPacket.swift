import Foundation

public struct EntityActionPacket: ServerboundPacket {
  public static let id: Int = 0x1c
  
  public var entityId: Int32
  public var action: PlayerEntityAction
  public var jumpBoost: Int32 = 0
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(entityId)
    writer.writeVarInt(action.rawValue)
    writer.writeVarInt(jumpBoost)
  }
}
