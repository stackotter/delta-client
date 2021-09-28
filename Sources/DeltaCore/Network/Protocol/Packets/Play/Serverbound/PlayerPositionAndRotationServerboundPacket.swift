//
//  PlayerPositionAndRotationServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct PlayerPositionAndRotationServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x13
  
  public var position: EntityPosition // y is feet position
  public var rotation: PlayerRotation
  public var onGround: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeEntityPosition(position)
    writer.writeFloat(rotation.yaw)
    writer.writeFloat(rotation.pitch)
    writer.writeBool(onGround)
  }
}
