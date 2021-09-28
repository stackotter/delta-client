//
//  ResourcePackStatusPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct ResourcePackStatusPacket: ServerboundPacket {
  public static let id: Int = 0x20
  
  public var result: ResourcePackStatus
  
  public enum ResourcePackStatus: Int32 {
    case successfullyLoaded = 0
    case declined = 1
    case failedDownload = 2
    case accepted = 3
  }
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(result.rawValue)
  }
}
