//
//  ClientboundPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation

protocol ClientboundPacket {
  static var id: Int { get }
  
  init(from packetReader: inout PacketReader) throws
  
  func handle(for server: Server) throws
  
  func handle(for serverPinger: ServerPinger) throws
}

extension ClientboundPacket {
  func handle(for server: Server) {
    return
  }
  
  func handle(for serverPinger: ServerPinger) {
    return
  }
}
