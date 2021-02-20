//
//  ChatMessagePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation
import os

struct ChatMessageClientboundPacket: ClientboundPacket {
  static let id: Int = 0x0e
  
  var message: ChatComponent
  var position: Int8
  var sender: UUID
  
  init(fromReader packetReader: inout PacketReader) throws {
    message = packetReader.readChat()
    position = packetReader.readByte()
    sender = packetReader.readUUID()
  }
  
  func handle(for server: Server) throws {
    Logger.log("chat message : \(message.toText())")
  }
}
