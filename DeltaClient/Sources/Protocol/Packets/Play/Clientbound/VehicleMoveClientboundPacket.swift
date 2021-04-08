//
//  VehicleMoveClientboundPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct VehicleMoveClientboundPacket: ClientboundPacket {
  static let id: Int = 0x2c
  
  var position: EntityPosition
  var yaw: Float
  var pitch: Float
  
  init(from packetReader: inout PacketReader) throws {
    position = packetReader.readEntityPosition()
    yaw = packetReader.readFloat()
    pitch = packetReader.readFloat()
  }
}
