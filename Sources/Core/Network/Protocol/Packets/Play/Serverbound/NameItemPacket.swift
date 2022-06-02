import Foundation

public struct NameItemPacket: ServerboundPacket {
  public static let id: Int = 0x1f
  
  public var itemName: String
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeString(itemName)
  }
}
