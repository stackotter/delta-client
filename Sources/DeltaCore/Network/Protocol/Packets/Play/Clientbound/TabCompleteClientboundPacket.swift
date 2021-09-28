//
//  TabCompleteClientboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct TabCompleteClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x10
  
  public struct TabCompleteMatch {
    public let match: String
    public let hasTooltip: Bool
    public let tooltip: ChatComponent?
  }
  
  public var id: Int
  public var start: Int
  public var length: Int
  public var matches: [TabCompleteMatch]
  
  public init(from packetReader: inout PacketReader) throws {
    id = packetReader.readVarInt()
    start = packetReader.readVarInt()
    length = packetReader.readVarInt()
    
    matches = []
    let count = packetReader.readVarInt()
    for _ in 0..<count {
      let match = try packetReader.readString()
      let hasTooltip = packetReader.readBool()
      var tooltip: ChatComponent?
      if hasTooltip {
        tooltip = try packetReader.readChat()
      }
      matches.append(TabCompleteMatch(match: match, hasTooltip: hasTooltip, tooltip: tooltip))
    }
  }
}
