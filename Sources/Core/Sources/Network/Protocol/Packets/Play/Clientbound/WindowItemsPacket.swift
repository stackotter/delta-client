import Foundation

public struct WindowItemsPacket: ClientboundPacket {
  public static let id: Int = 0x14
  
  public var windowId: UInt8
  public var slotData: [ItemStack]
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readUnsignedByte()
    
    slotData = []
    let count = try packetReader.readShort()
    for _ in 0..<count {
      let slot = try packetReader.readItemStack()
      slotData.append(slot)
    }
  }
}
