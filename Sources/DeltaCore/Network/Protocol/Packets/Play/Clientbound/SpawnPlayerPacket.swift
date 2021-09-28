//
//  SpawnPlayerPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct SpawnPlayerPacket: ClientboundPacket {
  public static let id: Int = 0x04
  
  public var entityId: Int
  public var playerUUID: UUID
  public var position: EntityPosition
  public var rotation: EntityRotation
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    playerUUID = try packetReader.readUUID()
    position = packetReader.readEntityPosition()
    rotation = packetReader.readEntityRotation()
  }
}
