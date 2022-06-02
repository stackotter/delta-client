import Foundation

public struct SelectTradePacket: ServerboundPacket {
  public static let id: Int = 0x22
  
  public var selectedSlot: Int32
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(selectedSlot)
  }
}
