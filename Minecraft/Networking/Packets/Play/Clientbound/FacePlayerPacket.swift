//
//  FacePlayerPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct FacePlayerPacket: ClientboundPacket {
  static let id: Int = 0x34

  var feetOrEyes: Int32
  var targetPosition: EntityPosition
  var isEntity: Bool
  var entityId: Int32?
  var entityFeetOrEyes: Int32?
  
  init(from packetReader: inout PacketReader) throws {
    feetOrEyes = packetReader.readVarInt()
    targetPosition = packetReader.readEntityPosition()
    isEntity = packetReader.readBool()
    if isEntity {
      entityId = packetReader.readVarInt()
      entityFeetOrEyes = packetReader.readVarInt()
    }
  }
}
