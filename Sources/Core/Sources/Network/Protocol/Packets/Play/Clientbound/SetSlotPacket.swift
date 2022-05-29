import Foundation

public struct SetSlotPacket: ClientboundPacket {
  public static let id: Int = 0x16
  
  public var windowId: Int8
  public var slot: Int16
  public var slotData: ItemStack
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readByte()
    slot = try packetReader.readShort()
    slotData = try packetReader.readItemStack()
  }
}
