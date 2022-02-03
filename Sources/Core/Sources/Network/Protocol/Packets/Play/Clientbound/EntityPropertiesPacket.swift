import Foundation

public struct EntityPropertiesPacket: ClientboundPacket {
  public static let id: Int = 0x58
  
  public var entityId: Int
  public var properties: [EntityProperty]
  
  // TODO_LATER: this deserves it's own file
  public struct EntityProperty {
    public var key: Identifier
    public var value: Double
    public var modifiers: [ModifierData]
  }
  
  public struct ModifierData {
    public var uuid: UUID
    public var amount: Double
    public var operation: Int8
  }

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    let numProperties = packetReader.readInt()
    properties = []
    for _ in 0..<numProperties {
      let key = try packetReader.readIdentifier()
      let value = packetReader.readDouble()
      let numModifiers = packetReader.readVarInt()
      var modifiers: [ModifierData] = []
      for _ in 0..<numModifiers {
        let uuid = try packetReader.readUUID()
        let amount = packetReader.readDouble()
        let operation = packetReader.readByte()
        let modifier = ModifierData(uuid: uuid, amount: amount, operation: operation)
        modifiers.append(modifier)
      }
      let property = EntityProperty(key: key, value: value, modifiers: modifiers)
      properties.append(property)
    }
  }
}
