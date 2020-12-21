//
//  Handshake.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation

struct Handshake: Packet {
  typealias PacketType = Handshake
  var id = 0x00
  
  var protocolVersion: Int
  var serverAddr: String
  var serverPort: Int
  var nextState: NextState
  
  enum NextState: Int {
    case status = 1
    case login = 2
  }
  
  func toBytes() -> [UInt8] {
    var writer = PacketWriter(packetId: id)
    writer.writeVarInt(Int32(protocolVersion))
    writer.writeString(serverAddr)
    writer.writeShort(UInt16(serverPort))
    writer.writeVarInt(Int32(nextState.rawValue))
    return writer.pack()
  }
}
