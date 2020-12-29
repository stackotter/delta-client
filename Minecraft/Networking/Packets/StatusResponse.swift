//
//  StatusResponse.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

struct StatusResponse: Packet {
  typealias PacketType = StatusResponse
  var id: Int = 0x00
  
  var json: JSON
  
  static func from(_ packetReader: PacketReader) -> StatusResponse? {
    var mutableReader = packetReader
    let json = mutableReader.readJSON()
    let packet = StatusResponse(json: json)
    return packet
  }
}
