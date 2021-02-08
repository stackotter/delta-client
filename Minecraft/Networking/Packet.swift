//
//  Packet.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation

enum PacketError: LocalizedError {
  case packetNotClientbound
}

protocol Packet {
  associatedtype PacketType: Packet
  
  static var id: Int { get }
  
  func toBytes() -> [UInt8]
  
  init(fromReader packetReader: inout PacketReader) throws
}

extension Packet {
  func toBytes() -> [UInt8] {
    print("toBytes called on packet without implementation")
    return []
  }
  
  init(fromReader packetReader: inout PacketReader) throws {
    throw PacketError.packetNotClientbound
  }
}
