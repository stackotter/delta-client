//
//  TabCompletePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct TabCompleteClientboundPacket: Packet {
  typealias PacketType = TabCompleteClientboundPacket
  static let id: Int = 0x10
  
  struct TabCompleteMatch {
    let match: String
    let hasTooltip: Bool
    let tooltip: String?
  }
  
  var id: Int32
  var start: Int32
  var length: Int32
  var matches: [TabCompleteMatch]
  
  init(fromReader packetReader: inout PacketReader) throws {
    id = packetReader.readVarInt()
    start = packetReader.readVarInt()
    length = packetReader.readVarInt()
    
    matches = []
    let count = packetReader.readVarInt()
    for _ in 0..<count {
      let match = packetReader.readString()
      let hasTooltip = packetReader.readBool()
      var tooltip: String?
      if hasTooltip {
        tooltip = packetReader.readChat()
      }
      matches.append(TabCompleteMatch(match: match, hasTooltip: hasTooltip, tooltip: tooltip))
    }
  }
}
