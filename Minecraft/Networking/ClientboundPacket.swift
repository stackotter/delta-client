//
//  ClientboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation

protocol ClientboundPacket {
  static var id: Int { get }
  
  init(fromReader packetReader: inout PacketReader) throws
  
  func handle(for server: Server) throws
}

extension ClientboundPacket {
  func handle(for server: Server) {
    return
  }
}
