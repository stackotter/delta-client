//
//  EntityEquipmentPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct EntityEquipmentPacket: ClientboundPacket {
  static let id: Int = 0x47
  
  var entityId: Int32
  var equipments: [Equipment]
  
  // TODO: could probably give this it's own file
  struct Equipment {
    var slot: UInt8
    var item: Slot
  }

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
      let item = try packetReader.readSlot()
      let equipment = Equipment(slot: slot, item: item)
      equipments.append(equipment)
    }
  }
}
