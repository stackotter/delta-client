//
//  LoginStartPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 15/12/20.
//

import Foundation

public struct LoginStartPacket: ServerboundPacket {
  public static let id: Int = 0x00
  
  public var username: String
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeString(username)
  }
}
