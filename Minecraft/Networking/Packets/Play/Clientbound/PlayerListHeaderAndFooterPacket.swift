//
//  PlayerListHeaderAndFooterPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct PlayerListHeaderAndFooterPacket: ClientboundPacket {
  static let id: Int = 0x53
  
  var header: ChatComponent
  var footer: ChatComponent

  init(from packetReader: inout PacketReader) throws {
    header = packetReader.readChat()
    footer = packetReader.readChat()
  }
}
