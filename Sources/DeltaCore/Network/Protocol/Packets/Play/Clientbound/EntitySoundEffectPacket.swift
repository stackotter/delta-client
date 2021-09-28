//
//  EntitySoundEffectPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

public struct EntitySoundEffectPacket: ClientboundPacket {
  public static let id: Int = 0x50
  
  public var soundId: Int
  public var soundCategory: Int
  public var entityId: Int
  public var volume: Float
  public var pitch: Float

  public init(from packetReader: inout PacketReader) throws {
    soundId = packetReader.readVarInt()
    soundCategory = packetReader.readVarInt()
    entityId = packetReader.readVarInt()
    volume = packetReader.readFloat()
    pitch = packetReader.readFloat()
  }
}
