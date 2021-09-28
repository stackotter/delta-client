import Foundation

public struct QueryEntityNBTPacket: ServerboundPacket {
  public static let id: Int = 0x0d
  
  public var transactionId: Int32
  public var entityId: Int32
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(transactionId)
    writer.writeVarInt(entityId)
  }
}
