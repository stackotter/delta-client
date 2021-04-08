//
//  StatusRequestPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

struct StatusRequestPacket: ServerboundPacket {
  static let id: Int = 0x00
  
  func writePayload(to writer: inout PacketWriter) {
    
  }
}
