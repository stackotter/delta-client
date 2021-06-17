//
//  PlayDisconnectPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation


struct PlayDisconnectPacket: ClientboundPacket {
  static let id: Int = 0x1a
  
  var reason: ChatComponent
  
  init(from packetReader: inout PacketReader) throws {
    reason = try packetReader.readChat()
  }
  
  func handle(for server: Server) throws {
    log.info("Disconnected from server: \(reason.toText())")
    DeltaCoreApp.triggerError(reason.toText())
  }
}
