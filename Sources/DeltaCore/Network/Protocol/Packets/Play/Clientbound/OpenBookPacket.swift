//
//  OpenBookPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

public struct OpenBookPacket: ClientboundPacket {
  public static let id: Int = 0x2d
  
  public var hand: Int
  
  public init(from packetReader: inout PacketReader) throws {
    hand = packetReader.readVarInt()
  }
}
