//
//  ChatMessagePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct ChatMessageClientboundPacket: Packet {
  typealias PacketType = ChatMessageClientboundPacket
  static let id: Int = 0x0e
  
  var jsonData: String
  var position: Int8
  var sender: UUID
  
  init(fromReader packetReader: inout PacketReader) throws {
    jsonData = packetReader.readChat()
    position = packetReader.readByte()
    sender = packetReader.readUUID()
  }
}
