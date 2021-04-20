//
//  ChatMessageClientboundPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation


struct ChatMessageClientboundPacket: ClientboundPacket {
  static let id: Int = 0x0e
  
  var message: ChatComponent
  var position: Int8
  var sender: UUID
  
  init(from packetReader: inout PacketReader) throws {
    message = try packetReader.readChat()
    position = packetReader.readByte()
    sender = try packetReader.readUUID()
  }
  
  func handle(for server: Server) throws {
    Logger.info("chat message : \(message.toText())")
  }
}
