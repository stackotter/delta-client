//
//  ClientStatusPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct ClientStatusPacket: ServerboundPacket {
  public static let id: Int = 0x04
  
  public var action: ClientStatusAction
  
  public enum ClientStatusAction: Int32 {
    case performRespawn = 0
    case requestStats = 1
  }
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(action.rawValue)
  }
}
