import Foundation

public struct EditBookPacket: ServerboundPacket {
  public static let id: Int = 0x0c
  
  public var newBook: Slot
  public var isSigning: Bool
  public var hand: Hand
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeSlot(newBook)
    writer.writeBool(isSigning)
    writer.writeVarInt(hand.rawValue)
  }
}
