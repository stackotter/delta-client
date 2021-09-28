//
//  EntityRotationPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

public struct EntityRotationPacket: ClientboundPacket {
  public static let id: Int = 0x2a

  public var entityId: Int
  public var rotation: EntityRotation
  public var onGround: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    rotation = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
}
