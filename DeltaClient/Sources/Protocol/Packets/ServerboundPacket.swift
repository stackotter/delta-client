//
//  ServerboundPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

protocol ServerboundPacket {
  static var id: Int { get }
  
  // writes payload to packetwriter (everything after packet id)
  func writePayload(to writer: inout PacketWriter)
}

extension ServerboundPacket {
  var id: Int {
    type(of: self).id
  }
  
  func toBuffer() -> Buffer {
    var writer = PacketWriter()
    writer.writeVarInt(Int32(id))
    writePayload(to: &writer)
    return writer.buffer
  }
}
