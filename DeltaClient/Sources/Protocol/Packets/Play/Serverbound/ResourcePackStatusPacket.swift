//
//  ResourcePackStatusPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct ResourcePackStatusPacket: ServerboundPacket {
  static let id: Int = 0x20
  
  var result: ResourcePackStatus
  
  enum ResourcePackStatus: Int32 {
    case successfullyLoaded = 0
    case declined = 1
    case failedDownload = 2
    case accepted = 3
  }
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(result.rawValue)
  }
}
