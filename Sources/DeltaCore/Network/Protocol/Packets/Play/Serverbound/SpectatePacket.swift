//
//  SpectatePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct SpectatePacket: ServerboundPacket {
  public static let id: Int = 0x2c
  
  public var targetPlayer: UUID
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeUUID(targetPlayer)
  }
}
