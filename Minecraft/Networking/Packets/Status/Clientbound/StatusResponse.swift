//
//  StatusResponse.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

struct StatusResponse: ClientboundPacket {
  
  static let id: Int = 0x00
  
  var json: JSON
  
  init(fromReader packetReader: inout PacketReader) throws {
    json = try packetReader.readJSON()
  }
}
