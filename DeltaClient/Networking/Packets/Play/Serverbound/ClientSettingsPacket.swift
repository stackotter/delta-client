//
//  ClientSettingsPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct ClientSettingsPacket: ServerboundPacket {
  static let id: Int = 0x05
  
  var locale: String
  var viewDistance: Int8
  var chatMode: ChatMode
  var chatColors: Bool
  var displayedSkinParts: SkinParts
  var mainHand: DominantHand
  
  enum ChatMode: Int32 {
    case enabled = 0
    case commandsOnly = 1
    case hidden = 2
  }
  
  struct SkinParts: OptionSet {
    let rawValue: UInt8
    
    static let cape = SkinParts(rawValue: 0x01)
    static let jacket = SkinParts(rawValue: 0x02)
    static let leftSleeve = SkinParts(rawValue: 0x04)
    static let rightSleeve = SkinParts(rawValue: 0x08)
    static let leftPantsLeg = SkinParts(rawValue: 0x10)
    static let rightPantsLeg = SkinParts(rawValue: 0x20)
    static let hat = SkinParts(rawValue: 0x40)
  }
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeString(locale)
    writer.writeByte(viewDistance)
    writer.writeVarInt(chatMode.rawValue)
    writer.writeBool(chatColors)
    writer.writeUnsignedByte(displayedSkinParts.rawValue)
    writer.writeVarInt(mainHand.rawValue)
  }
}
