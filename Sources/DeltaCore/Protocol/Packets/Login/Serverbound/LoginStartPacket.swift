//
//  LoginStartPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 15/12/20.
//

import Foundation

struct LoginStartPacket: ServerboundPacket {
  static let id: Int = 0x00
  
  var username: String
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeString(username)
  }
}
