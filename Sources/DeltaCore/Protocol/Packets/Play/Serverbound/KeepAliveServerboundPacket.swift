//
//  KeepAliveServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct KeepAliveServerBoundPacket: ServerboundPacket {
  static let id: Int = 0x10
  
  var keepAliveId: Int
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeLong(Int64(keepAliveId))
  }
}
