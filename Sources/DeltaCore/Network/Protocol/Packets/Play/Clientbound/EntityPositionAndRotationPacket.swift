//
//  EntityPositionAndRotationPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

public struct EntityPositionAndRotationPacket: ClientboundPacket {
  public static let id: Int = 0x29

  public var entityId: Int
  public var deltaX: Int16
  public var deltaY: Int16
  public var deltaZ: Int16
  public var rotation: EntityRotation
  public var onGround: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    deltaX = packetReader.readShort()
    deltaY = packetReader.readShort()
    deltaZ = packetReader.readShort()
    rotation = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
}
