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
  
  static func from(_ packetReader: PacketReader) throws -> TagsPacket? {
    var mutableReader = packetReader
    for _ in 1...4 {
      let length = mutableReader.readVarInt()
      for _ in 1...length {
        let tagName = mutableReader.readString()
        _ = tagName
        let count = mutableReader.readVarInt()
        for _ in 1...count {
          let entry = mutableReader.readVarInt()
          _ = entry
        }
      }
    }
    return TagsPacket()
  }
}
