//
//  NBTQueryResponse.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct NBTQueryResponse: ClientboundPacket {
  static let id: Int = 0x54
  
  var transactionId: Int32
  var nbt: NBTCompound

  init(from packetReader: inout PacketReader) throws {
    transactionId = packetReader.readVarInt()
    // TODO: make nbt just pass too maybe?
    nbt = try packetReader.readNBTTag()
  }
}
