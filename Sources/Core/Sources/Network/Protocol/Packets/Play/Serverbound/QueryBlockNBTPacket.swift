import Foundation

public struct QueryBlockNBTPacket: ServerboundPacket {
  public static let id: Int = 0x01
  
  public var transactionId: Int32
  public var location: Position
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(transactionId)
    writer.writePosition(location)
  }
}
