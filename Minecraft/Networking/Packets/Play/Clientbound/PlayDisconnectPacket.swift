//
//  PlayDisconnectPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct PlayDisconnectPacket: Packet {
  typealias PacketType = PlayDisconnectPacket
  static let id: Int = 0x1a
  
  var reason: String
  
  init(fromReader packetReader: inout PacketReader) throws {
    reason = packetReader.readChat()
  }
}
