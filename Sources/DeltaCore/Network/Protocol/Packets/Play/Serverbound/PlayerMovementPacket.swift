//
//  PlayerMovementPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct PlayerMovementPacket: ServerboundPacket {
  public static let id: Int = 0x15
  
  public var onGround: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeBool(onGround)
  }
}
