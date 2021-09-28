//
//  ServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

public protocol ServerboundPacket {
  static var id: Int { get }
  
  // writes payload to packetwriter (everything after packet id)
  func writePayload(to writer: inout PacketWriter)
}

extension ServerboundPacket {
  public func toBuffer() -> Buffer {
    var writer = PacketWriter()
    writer.writeVarInt(Int32(Self.id))
    writePayload(to: &writer)
    return writer.buffer
  }
}
