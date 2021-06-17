//
//  LoginDisconnectPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct LoginDisconnectPacket: ClientboundPacket {
  static let id: Int = 0x00
  
  var reason: ChatComponent
  
  init(from packetReader: inout PacketReader) throws {
    reason = try packetReader.readChat()
  }
  
  func handle(for server: Server) throws {
    DeltaCoreApp.triggerError(reason.toText())
  }
}
