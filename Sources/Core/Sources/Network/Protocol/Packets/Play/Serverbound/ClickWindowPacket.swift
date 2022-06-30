import Foundation

public struct ClickWindowPacket: ServerboundPacket {
  public static let id: Int = 0x09

  public var windowId: UInt8
  public var slot: Int16
  public var button: Int8
  public var actionNumber: Int16
  public var mode: Int32
  public var clickedItem: Slot

  public func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(windowId)
    writer.writeShort(slot)
    writer.writeByte(button)
    writer.writeShort(actionNumber)
    writer.writeVarInt(mode)
    writer.writeSlot(clickedItem)
  }
}
