//
//  RespawnPacket.swift
//  Minecraft
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
    gamemode = Gamemode(rawValue: packetReader.readByte())!
    previousGamemode = Gamemode(rawValue: packetReader.readByte())!
    isDebug = packetReader.readBool()
    isFlat = packetReader.readBool()
    copyMetadata = packetReader.readBool() // TODO_LATER: not used yet
  }
  
  func handle(for server: Server) throws {
    if let world = server.worlds[worldName] {
      world.config = WorldConfig(
        worldName: worldName, dimension: dimension,
        hashedSeed: hashedSeed, isDebug: isDebug, isFlat: isFlat
      )
    } else {
      let worldConfig = WorldConfig(
        worldName: worldName, dimension: dimension,
        hashedSeed: hashedSeed, isDebug: isDebug, isFlat: isFlat
      )
      server.addWorld(config: worldConfig)
      server.setCurrentWorld(identifier: worldName)
    }
    server.currentWorldName = worldName
    server.player.gamemode = gamemode
  }
}
