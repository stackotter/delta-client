//
//  UpdateJigsawBlockPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct UpdateJigsawBlockPacket: ServerboundPacket {
  static let id: Int = 0x28
  
  var location: Position
  var name: Identifier
  var target: Identifier
  var pool: Identifier
  var finalState: String
  var jointType: String
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writePosition(location)
    writer.writeIdentifier(name)
    writer.writeIdentifier(target)
    writer.writeIdentifier(pool)
    writer.writeString(finalState)
    writer.writeString(jointType)
  }
}
