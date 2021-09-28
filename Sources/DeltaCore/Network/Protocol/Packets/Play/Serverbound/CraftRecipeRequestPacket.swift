//
//  CraftRecipeRequestPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct CraftRecipeRequestPacket: ServerboundPacket {
  public static let id: Int = 0x19
  
  public var windowId: Int8
  public var recipe: Identifier
  public var makeAll: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeByte(windowId)
    writer.writeIdentifier(recipe)
    writer.writeBool(makeAll)
  }
}
