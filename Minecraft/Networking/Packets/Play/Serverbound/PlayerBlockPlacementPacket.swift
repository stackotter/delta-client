//
//  PlayerBlockPlacementPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct PlayerBlockPlacementPacket: ServerboundPacket {
  static let id: Int = 0x2d
  
  var hand: Hand
  var location: Position
  var face: Direction
  var cursorPositionX: Float
  var cursorPositionY: Float
  var cursorPositionZ: Float
  var insideBlock: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(hand.rawValue)
    writer.writePosition(location)
    writer.writeVarInt(Int32(face.rawValue)) // wth mojang, why is it a varInt here and a byte somewhere else. it's literally the same enum! >:(
    writer.writeFloat(cursorPositionX)
    writer.writeFloat(cursorPositionY)
    writer.writeFloat(cursorPositionZ)
    writer.writeBool(insideBlock)
  }
}
