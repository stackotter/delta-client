//
//  UpdateCommandBlockMinecartPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct UpdateCommandBlockMinecartPacket: ServerboundPacket {
  public static let id: Int = 0x26
  
  public var entityId: Int32
  public var command: String
  public var trackOutput: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(entityId)
    writer.writeString(command)
    writer.writeBool(trackOutput)
  }
}
