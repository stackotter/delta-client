//
//  SoundEffectPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

public struct SoundEffectPacket: ClientboundPacket {
  public static let id: Int = 0x51
  
  public var soundId: Int
  public var soundCategory: Int
  public var effectPositionX: Int
  public var effectPositionY: Int
  public var effectPositionZ: Int
  public var volume: Float
  public var pitch: Float

  public init(from packetReader: inout PacketReader) throws {
    soundId = packetReader.readVarInt()
    soundCategory = packetReader.readVarInt()
    effectPositionX = packetReader.readInt()
    effectPositionY = packetReader.readInt()
    effectPositionZ = packetReader.readInt()
    volume = packetReader.readFloat()
    pitch = packetReader.readFloat()
  }
}
