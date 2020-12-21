//
//  Packet.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/12/20.
//

import Foundation

protocol Packet {
  associatedtype PacketType: Packet
  
  var id: Int { get }
  
  func toBytes() -> [UInt8]
  
  static func from(_ reader: PacketReader) -> PacketType?
}

extension Packet {
  func toBytes() -> [UInt8] {
    return []
  }
  
  static func from(_ reader: PacketReader) -> PacketType? {
    return nil
  }
}
