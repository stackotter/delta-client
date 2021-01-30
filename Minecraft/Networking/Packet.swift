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
  
  static func from(_ packetReader: inout PacketReader) throws -> PacketType
}

extension Packet {
  func toBytes() -> [UInt8] {
    print("toBytes called on packet without implementation")
    return []
  }
  
  static func from(_ packetReader: inout PacketReader) throws -> PacketType {
    throw PacketError.packetNotClientbound
  }
}
