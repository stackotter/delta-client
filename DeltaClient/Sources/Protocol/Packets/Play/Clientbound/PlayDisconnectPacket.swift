//
//  PlayDisconnectPacket.swift
//  DeltaClient
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
    Logger.info("disconnected: \(reason.toText())")
    DeltaClientApp.triggerError(reason.toText())
  }
}
