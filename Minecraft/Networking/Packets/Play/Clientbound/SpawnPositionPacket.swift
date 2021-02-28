//
//  SpawnPositionPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct SpawnPositionPacket: ClientboundPacket {
  static let id: Int = 0x42
  
  var location: Position

  init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
  }
  
  func handle(for server: Server) throws {
    server.player.position.x = Double(location.x)
    server.player.position.y = Double(location.y)
    server.player.position.z = Double(location.z)
  }
}
