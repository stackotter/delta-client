//
//  CraftRecipeRequestPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct CraftRecipeRequestPacket: ServerboundPacket {
  static let id: Int = 0x19
  
  var windowId: Int8
  var recipe: Identifier
  var makeAll: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeByte(windowId)
    writer.writeIdentifier(recipe)
    writer.writeBool(makeAll)
  }
}
