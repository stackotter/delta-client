//
//  EntityProperties.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct EntityProperties: ClientboundPacket {
  static let id: Int = 0x58
  
  var entityId: Int32
  var properties: [EntityProperty]
  
  // TODO_LATER: this deserves it's own file
  struct EntityProperty {
    var key: Identifier
    var value: Double
    var modifiers: [ModifierData]
  }
  
  struct ModifierData {
    var uuid: UUID
    var amount: Double
    var operation: Int8
  }

  init(fromReader packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    let numProperties = packetReader.readInt()
    properties = []
    for _ in 0..<numProperties {
      let key = try packetReader.readIdentifier()
      let value = packetReader.readDouble()
      let numModifiers = packetReader.readVarInt()
      var modifiers: [ModifierData] = []
      for _ in 0..<numModifiers {
        let uuid = packetReader.readUUID()
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
