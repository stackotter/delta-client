//
//  StatusRequest.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

struct StatusRequest: ServerboundPacket {
  static let id: Int = 0x00
  
  func toBytes() -> [UInt8] {
    var writer = PacketWriter(packetId: id)
    return writer.pack()
  }
}
