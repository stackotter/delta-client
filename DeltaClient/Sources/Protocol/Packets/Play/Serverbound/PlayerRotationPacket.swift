//
//  PlayerRotationPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct PlayerRotationPacket: ServerboundPacket {
  static let id: Int = 0x14
  
  var rotation: PlayerRotation
  var onGround: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeFloat(rotation.yaw)
    writer.writeFloat(rotation.pitch)
    writer.writeBool(onGround)
  }
}
