//
//  HandshakePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation

public struct HandshakePacket: ServerboundPacket {
  public static let id: Int = 0x00
  
  public var protocolVersion: Int
  public var serverAddr: String
  public var serverPort: Int
  public var nextState: NextState
  
  public enum NextState: Int {
    case status = 1
    case login = 2
  }
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(Int32(protocolVersion))
    writer.writeString(serverAddr)
    writer.writeUnsignedShort(UInt16(serverPort))
    writer.writeVarInt(Int32(nextState.rawValue))
  }
}
