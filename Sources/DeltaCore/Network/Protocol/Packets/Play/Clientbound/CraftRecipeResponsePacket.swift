//
//  CraftRecipeResponsePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

public struct CraftRecipeResponsePacket: ClientboundPacket {
  public static let id: Int = 0x30
  
  public var windowId: Int8
  public var recipe: Identifier
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readByte()
    recipe = try packetReader.readIdentifier()
  }
}
