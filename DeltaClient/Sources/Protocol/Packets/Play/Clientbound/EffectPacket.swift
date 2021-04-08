//
//  EffectPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct EffectPacket: ClientboundPacket {
  static let id: Int = 0x22
  
  var effectId: Int
  var location: Position
  var data: Int
  var disableRelativeVolume: Bool
  
  init(from packetReader: inout PacketReader) throws {
    effectId = packetReader.readInt()
    location = packetReader.readPosition()
    data = packetReader.readInt()
    disableRelativeVolume = packetReader.readBool()
  }
}
