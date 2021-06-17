//
//  HandshakePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation

struct HandshakePacket: ServerboundPacket {
  static let id: Int = 0x00
  
  var protocolVersion: Int
  var serverAddr: String
  var serverPort: Int
  var nextState: NextState
  
  enum NextState: Int {
    case status = 1
    case login = 2
  }
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(Int32(protocolVersion))
    writer.writeString(serverAddr)
    writer.writeUnsignedShort(UInt16(serverPort))
    writer.writeVarInt(Int32(nextState.rawValue))
  }
}
