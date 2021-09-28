//
//  PlayerAbilitiesServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct PlayerAbilitiesServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x1a
  
  public var flags: PlayerAbilities
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(flags.rawValue)
  }
}
