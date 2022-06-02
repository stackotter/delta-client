import Foundation

public struct EntityEquipmentPacket: ClientboundPacket {
  public static let id: Int = 0x47
  
  public var entityId: Int
  public var equipments: [Equipment]

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    equipments = []
    var isLastEquipment = false
    while !isLastEquipment {
      var slot = try packetReader.readUnsignedByte()
      if slot & 0x80 != 0x80 {
        isLastEquipment = true
      }
      slot = slot & 0x7f
      let item = try packetReader.readItemStack()
      let equipment = Equipment(slot: slot, item: item)
      equipments.append(equipment)
    }
  }
}
