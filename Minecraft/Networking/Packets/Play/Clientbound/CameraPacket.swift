//
//  CameraPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct CameraPacket: ClientboundPacket {
  static let id: Int = 0x3e
  
  var cameraEntityId: Int32

  init(from packetReader: inout PacketReader) throws {
    cameraEntityId = packetReader.readVarInt()
  }
}
