//
//  EffectPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct EffectPacket: Packet {
  typealias PacketType = EffectPacket
  static let id: Int = 0x22
  
  var effectId: Int32
  var location: Position
  var data: Int32
  var disableRelativeVolume: Bool
  
  init(fromReader packetReader: inout PacketReader) throws {
    effectId = packetReader.readInt()
    location = packetReader.readPosition()
    data = packetReader.readInt()
    disableRelativeVolume = packetReader.readBool()
  }
}
