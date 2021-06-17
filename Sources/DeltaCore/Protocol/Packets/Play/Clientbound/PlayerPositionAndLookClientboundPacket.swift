//
//  PlayerPositionAndLookClientboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation


struct PlayerPositionAndLookClientboundPacket: ClientboundPacket {
  static let id: Int = 0x35
  
  var position: EntityPosition
  var yaw: Float
  var pitch: Float
  var flags: PositionAndLookFlags
  var teleportId: Int
  
  struct PositionAndLookFlags: OptionSet {
    let rawValue: UInt8
    
    static let x = PositionAndLookFlags(rawValue: 0x01)
    static let y = PositionAndLookFlags(rawValue: 0x02)
    static let z = PositionAndLookFlags(rawValue: 0x04)
    static let yRot = PositionAndLookFlags(rawValue: 0x08)
    static let xRot = PositionAndLookFlags(rawValue: 0x10)
  }

  init(from packetReader: inout PacketReader) throws {
    position = packetReader.readEntityPosition()
    yaw = packetReader.readFloat()
    pitch = packetReader.readFloat()
    flags = PositionAndLookFlags(rawValue: packetReader.readUnsignedByte())
    teleportId = packetReader.readVarInt()
  }
  
  func handle(for server: Server) throws {
    let teleportConfirm = TeleportConfirmPacket(teleportId: teleportId)
    server.sendPacket(teleportConfirm)
    
    if flags.contains(.x) {
      server.player.position.x += position.x
    } else {
      server.player.position.x = position.x
    }
    
    if flags.contains(.y) {
      server.player.position.y += position.y
    } else {
      server.player.position.y = position.y
    }
    
    if flags.contains(.z) {
      server.player.position.z += position.z
    } else {
      server.player.position.z = position.z
    }
    
    if flags.contains(.yRot) {
      server.player.look.yaw += yaw
    } else {
      server.player.look.yaw = yaw
    }
    
    if flags.contains(.xRot) {
      server.player.look.pitch += pitch
    } else {
      server.player.look.pitch = pitch
    }
  }
}
