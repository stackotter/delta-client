//
//  BlockEntityDataPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct BlockEntityDataPacket: ClientboundPacket {
  static let id: Int = 0x09
  
  var location: Position
  var action: UInt8
  var nbtData: NBTCompound
  
  init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
    action = packetReader.readUnsignedByte()
    nbtData = try packetReader.readNBTTag()
  }
}
