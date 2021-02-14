//
//  CraftRecipeResponsePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct CraftRecipeResponsePacket: ClientboundPacket {
  static let id: Int = 0x30
  
  var windowId: Int8
  var recipe: Identifier
  
  init(fromReader packetReader: inout PacketReader) throws {
    windowId = packetReader.readByte()
    recipe = try packetReader.readIdentifier()
  }
}
