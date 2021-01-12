//
//  JoinGame.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct JoinGamePacket: Packet {
  typealias PacketType = JoinGamePacket
  var id: Int = 0x24
  
  var playerEntityId: Int32
  var isHardcore: Bool
  var gamemode: Gamemode
  var previousGamemode: Gamemode
  var worldCount: Int32
  var worldNames: [Identifier]
  var dimensionCodec: NBTCompound
  var dimension: NBTCompound
  var worldName: Identifier
  var hashedSeed: Int64
  var maxPlayers: Int32
  var viewDistance: Int32
  var reducedDebugInfo: Bool
  var enableRespawnScreen: Bool
  var isDebug: Bool
  var isFlat: Bool
  
  static func from(_ packetReader: PacketReader) throws -> JoinGamePacket? {
    var mutableReader = packetReader
    let playerEntityId = mutableReader.readInt()
    let isHardcore = try mutableReader.readBool()
    let gamemode = Gamemode(rawValue: Int8(mutableReader.readUnsignedByte()))!
    let previousGamemode = Gamemode(rawValue: mutableReader.readByte())!
    let worldCount = mutableReader.readVarInt()
    var worldNames: [Identifier] = []
    for _ in 0..<worldCount {
      worldNames.append(try mutableReader.readIdentifier())
    }
    let dimensionCodec = try mutableReader.readNBTTag()
    let dimension = try mutableReader.readNBTTag()
    let worldName = try mutableReader.readIdentifier()
    let hashedSeed = mutableReader.readLong()
    let maxPlayers = mutableReader.readVarInt()
    let viewDistance = mutableReader.readVarInt()
    let reducedDebugInfo = try mutableReader.readBool()
    let enableRespawnScreen = try mutableReader.readBool()
    let isDebug = try mutableReader.readBool()
    let isFlat = try mutableReader.readBool()
    let packet = JoinGamePacket(playerEntityId: playerEntityId, isHardcore: isHardcore, gamemode: gamemode,
                          previousGamemode: previousGamemode, worldCount: worldCount, worldNames: worldNames,
                          dimensionCodec: dimensionCodec, dimension: dimension, worldName: worldName, hashedSeed: hashedSeed,
                          maxPlayers: maxPlayers, viewDistance: viewDistance, reducedDebugInfo: reducedDebugInfo,
                          enableRespawnScreen: enableRespawnScreen, isDebug: isDebug, isFlat: isFlat)
    return packet
  }
}

