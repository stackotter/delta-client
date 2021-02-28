//
//  TimeUpdatePacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

struct TimeUpdatePacket: ClientboundPacket {
  static let id: Int = 0x4e
  
  var worldAge: Int64
  var timeOfDay: Int64

  init(from packetReader: inout PacketReader) throws {
    worldAge = packetReader.readLong()
    timeOfDay = packetReader.readLong()
  }
  
  func handle(for server: Server) throws {
    server.currentWorld.age = worldAge
    server.timeOfDay = timeOfDay
  }
}
