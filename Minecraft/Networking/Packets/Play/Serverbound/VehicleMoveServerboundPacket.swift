//
//  VehicleMoveServerboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct VehicleMoveServerboundPacket: ServerboundPacket {
  static let id: Int = 0x16
  
  var position: EntityPosition
  var rotation: PlayerRotation
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeEntityPosition(position)
    writer.writeFloat(rotation.yaw)
    writer.writeFloat(rotation.pitch)
  }
}
