import Foundation

public enum EntityAttributesPacketError: LocalizedError {
  case invalidModifierOperationRawValue(UInt8)
  case invalidAttributeKey(String)
  
  public var errorDescription: String? {
    switch self {
      case .invalidModifierOperationRawValue(let rawValue):
        return """
        Invalid modifier operation.
        Raw value: \(rawValue)
        """
      case .invalidAttributeKey(let attributeKey):
        return "Invalid attribute key: \(attributeKey)"
    }
  }
}

public struct EntityAttributesPacket: ClientboundPacket {
  public static let id: Int = 0x58

  public var entityId: Int
  public var attributes: [EntityAttributeKey: EntityAttributeValue]

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()

    attributes = [:]
    let numProperties = try packetReader.readInt()
    for _ in 0..<numProperties {
      let key = try packetReader.readIdentifier()
      guard let attributeKey = EntityAttributeKey(rawValue: key.description) else {
        throw EntityAttributesPacketError.invalidAttributeKey(key.description)
      }

      let value = try packetReader.readDouble()

      var modifiers: [EntityAttributeModifier] = []
      let numModifiers = try packetReader.readVarInt()
      for _ in 0..<numModifiers {
        let uuid = try packetReader.readUUID()
        let amount = try packetReader.readDouble()
        let rawOperation = try packetReader.readUnsignedByte()
        guard let operation = EntityAttributeModifier.Operation(rawValue: rawOperation) else {
          throw EntityAttributesPacketError.invalidModifierOperationRawValue(rawOperation)
        }
        let modifier = EntityAttributeModifier(uuid: uuid, amount: amount, operation: operation)
        modifiers.append(modifier)
      }

      let attributeValue = EntityAttributeValue(baseValue: value, modifiers: modifiers)
      attributes[attributeKey] = attributeValue
    }
  }

  public func handle(for client: Client) throws {
    client.game.accessEntity(id: entityId) { entity in
      guard let attributesComponent: EntityAttributes = entity.get() else {
        log.warning("Entity attributes for entity with no attributes component: eid=\(entityId)")
        return
      }

      for (key, value) in attributes {
        attributesComponent[key] = value
      }
    }
  }
}
