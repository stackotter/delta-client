//
//  EntityEquipmentPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct EntityEquipmentPacket: ClientboundPacket {
  static let id: Int = 0x47
  
  var entityId: Int
  var equipments: [Equipment]

  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    equipments = []
    var isLastEquipment = false
    while !isLastEquipment {
      var slot = packetReader.readUnsignedByte()
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
