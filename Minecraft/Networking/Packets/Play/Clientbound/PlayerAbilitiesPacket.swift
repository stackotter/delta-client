//
//  PlayerAbilities.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct PlayerAbilitiesPacket: ClientboundPacket {
  static let id: Int = 0x31
  
  var flags: PlayerFlags
  var flyingSpeed: Float
  var fovModifier: Float
  
  init(fromReader packetReader: inout PacketReader) {
    flags = PlayerFlags(rawValue: packetReader.readUnsignedByte())
    flyingSpeed = packetReader.readFloat()
    fovModifier = packetReader.readFloat()
  }
  
  func handle(for server: Server) throws {
    server.player.flyingSpeed = flyingSpeed
    server.player.fovModifier = fovModifier
    server.player.updateFlags(to: flags)
  }
}
