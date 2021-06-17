//
//  ClientStatusPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct ClientStatusPacket: ServerboundPacket {
  static let id: Int = 0x04
  
  var action: ClientStatusAction
  
  enum ClientStatusAction: Int32 {
    case performRespawn = 0
    case requestStats = 1
  }
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(action.rawValue)
  }
}
