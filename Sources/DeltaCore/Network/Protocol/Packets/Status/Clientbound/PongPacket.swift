//
//  PongPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

public struct PongPacket: ClientboundPacket {
  public static let id: Int = 0x01
  
  public var payload: Int
  
  public init(from packetReader: inout PacketReader) throws {
    payload = packetReader.readLong()
  }
}
