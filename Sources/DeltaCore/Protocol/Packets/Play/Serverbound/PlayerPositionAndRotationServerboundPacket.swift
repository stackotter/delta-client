//
//  PlayerPositionAndRotationServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct PlayerPositionAndRotationServerboundPacket: ServerboundPacket {
  static let id: Int = 0x13
  
  var position: EntityPosition // y is feet position
  var rotation: PlayerRotation
  var onGround: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeEntityPosition(position)
    writer.writeFloat(rotation.yaw)
    writer.writeFloat(rotation.pitch)
    writer.writeBool(onGround)
  }
}
