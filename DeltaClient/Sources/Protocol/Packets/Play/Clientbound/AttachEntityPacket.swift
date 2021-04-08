//
//  AttachEntityPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct AttachEntityPacket: ClientboundPacket {
  static let id: Int = 0x45
  
  var attachedEntityId: Int
  var holdingEntityId: Int

  init(from packetReader: inout PacketReader) throws {
    attachedEntityId = packetReader.readInt()
    holdingEntityId = packetReader.readInt()
  }
}
