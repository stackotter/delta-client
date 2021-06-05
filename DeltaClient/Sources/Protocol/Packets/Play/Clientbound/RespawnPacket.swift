//
//  RespawnPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct RespawnPacket: ClientboundPacket {
  static let id: Int = 0x3a
  
  var dimension: Identifier
  var worldName: Identifier
  var hashedSeed: Int
  var gamemode: Gamemode
  var previousGamemode: Gamemode
  var isDebug: Bool
  var isFlat: Bool
  var copyMetadata: Bool

  init(from packetReader: inout PacketReader) throws {
    dimension = try packetReader.readIdentifier()
    worldName = try packetReader.readIdentifier()
    hashedSeed = packetReader.readLong()
    guard
      let gamemode = Gamemode(rawValue: packetReader.readByte()),
      let previousGamemode = Gamemode(rawValue: packetReader.readByte())
    else {
      throw ClientboundPacketError.invalidGamemode
    }
    self.gamemode = gamemode
    self.previousGamemode = previousGamemode
    isDebug = packetReader.readBool()
    isFlat = packetReader.readBool()
    copyMetadata = packetReader.readBool() // TODO_LATER: not used yet
  }
  
  func handle(for server: Server) throws {
    let worldInfo = World.Info(
      name: worldName,
      dimension: dimension,
      hashedSeed: hashedSeed,
      isDebug: isDebug,
      isFlat: isFlat)
    
    if let world = server.world {
      world.setInfo(worldInfo)
    } else {
      server.joinWorld(info: worldInfo)
    }
    server.player.gamemode = gamemode
    
    // TODO: get auto respawn working
    let clientStatus = ClientStatusPacket(action: .performRespawn)
    server.sendPacket(clientStatus)
  }
}
