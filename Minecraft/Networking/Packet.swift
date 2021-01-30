//
//  Packet.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation

protocol Packet {
  associatedtype PacketType: Packet
  
  static var id: Int { get }
  
  func toBytes() -> [UInt8]
  
  static func from(_ packetReader: inout PacketReader) -> PacketType?
}

extension Packet {
  func toBytes() -> [UInt8] {
    print("toBytes called on packet without implementation")
    return []
  }
  
  static func from(_ packetReader: inout PacketReader) -> PacketType? {
    return nil
  }
}
