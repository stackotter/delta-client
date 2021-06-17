//
//  UpdateCommandBlockPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct UpdateCommandBlockPacket: ServerboundPacket {
  static let id: Int = 0x25
  
  var location: Position
  var command: String
  var mode: CommandBlockMode
  var flags: CommandBlockFlags
  
  enum CommandBlockMode: Int32 {
    case sequence = 0
    case auto = 1
    case redstone = 2
  }
  
  struct CommandBlockFlags: OptionSet {
    let rawValue: UInt8
    
    static let trackOutput = CommandBlockFlags(rawValue: 0x01)
    static let isConditional = CommandBlockFlags(rawValue: 0x02)
    static let automatic = CommandBlockFlags(rawValue: 0x04)
  }
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writePosition(location)
    writer.writeString(command)
    writer.writeVarInt(mode.rawValue)
    writer.writeUnsignedByte(flags.rawValue)
  }
}
