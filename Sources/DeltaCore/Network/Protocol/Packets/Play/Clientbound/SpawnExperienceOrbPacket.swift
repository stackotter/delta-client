//
//  SpawnExperienceOrbPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 8/2/21.
//

import Foundation

public struct SpawnExperienceOrbPacket: ClientboundPacket {
  public static let id: Int = 0x01
  
  public var entityId: Int
  public var position: EntityPosition
  public var count: Int16
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    count = packetReader.readShort()
  }
}
