//
//  ClientSettingsPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct ClientSettingsPacket: ServerboundPacket {
  public static let id: Int = 0x05
  
  public var locale: String
  public var viewDistance: Int8
  public var chatMode: ChatMode
  public var chatColors: Bool
  public var displayedSkinParts: SkinParts
  public var mainHand: DominantHand
  
  public enum ChatMode: Int32 {
    case enabled = 0
    case commandsOnly = 1
    case hidden = 2
  }
  
  public struct SkinParts: OptionSet {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }
    
    public static let cape = SkinParts(rawValue: 0x01)
    public static let jacket = SkinParts(rawValue: 0x02)
    public static let leftSleeve = SkinParts(rawValue: 0x04)
    public static let rightSleeve = SkinParts(rawValue: 0x08)
    public static let leftPantsLeg = SkinParts(rawValue: 0x10)
    public static let rightPantsLeg = SkinParts(rawValue: 0x20)
    public static let hat = SkinParts(rawValue: 0x40)
  }
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeString(locale)
    writer.writeByte(viewDistance)
    writer.writeVarInt(chatMode.rawValue)
    writer.writeBool(chatColors)
    writer.writeUnsignedByte(displayedSkinParts.rawValue)
    writer.writeVarInt(mainHand.rawValue)
  }
}
