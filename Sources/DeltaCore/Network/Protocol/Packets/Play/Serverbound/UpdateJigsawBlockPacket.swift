//
//  UpdateJigsawBlockPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct UpdateJigsawBlockPacket: ServerboundPacket {
  public static let id: Int = 0x28
  
  public var location: Position
  public var name: Identifier
  public var target: Identifier
  public var pool: Identifier
  public var finalState: String
  public var jointType: String
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writePosition(location)
    writer.writeIdentifier(name)
    writer.writeIdentifier(target)
    writer.writeIdentifier(pool)
    writer.writeString(finalState)
    writer.writeString(jointType)
  }
}
