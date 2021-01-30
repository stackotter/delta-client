//
//  Tags.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/1/21.
//

import Foundation

// TODO_LATER: fill this out more as needed
struct TagsPacket: Packet {
  typealias PacketType = TagsPacket
  static let id: Int = 0x5b
  
  static func from(_ packetReader: inout PacketReader) -> TagsPacket {
    for _ in 1...4 {
      let length = packetReader.readVarInt()
      for _ in 1...length {
        let tagName = packetReader.readString()
        _ = tagName
        let count = packetReader.readVarInt()
        for _ in 1...count {
          let entry = packetReader.readVarInt()
          _ = entry
        }
      }
    }
    return TagsPacket()
  }
}
