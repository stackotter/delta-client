//
//  PlayerDiggingPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct PlayerDiggingPacket: ServerboundPacket {
  static let id: Int = 0x1b
  
  var status: DiggingStatus
  var location: Position
  var face: BlockFace
  
  enum DiggingStatus: Int32 {
    case startedDigging = 0
    case cancelledDigging = 1
    case finishedDigging = 2
    case dropItemStack = 3
    case dropItem = 4
    case shootArrowOrFinishEating = 5
    case swapItemInHand = 6
  }
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(status.rawValue)
    writer.writePosition(location)
    writer.writeByte(face.rawValue)
  }
}
