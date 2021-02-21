//
//  TabCompleteClientboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct TabCompleteClientboundPacket: ClientboundPacket {
  static let id: Int = 0x10
  
  struct TabCompleteMatch {
    let match: String
    let hasTooltip: Bool
    let tooltip: ChatComponent?
  }
  
  var id: Int32
  var start: Int32
  var length: Int32
  var matches: [TabCompleteMatch]
  
  init(from packetReader: inout PacketReader) throws {
    id = packetReader.readVarInt()
    start = packetReader.readVarInt()
    length = packetReader.readVarInt()
    
    matches = []
    let count = packetReader.readVarInt()
    for _ in 0..<count {
      let match = packetReader.readString()
      let hasTooltip = packetReader.readBool()
      var tooltip: ChatComponent?
      if hasTooltip {
        tooltip = packetReader.readChat()
      }
      matches.append(TabCompleteMatch(match: match, hasTooltip: hasTooltip, tooltip: tooltip))
    }
  }
}
