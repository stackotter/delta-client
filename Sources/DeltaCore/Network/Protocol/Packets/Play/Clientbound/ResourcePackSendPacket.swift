//
//  ResourcePackSendPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

public struct ResourcePackSendPacket: ClientboundPacket {
  public static let id: Int = 0x39
  
  public var url: String
  public var hash: String

  public init(from packetReader: inout PacketReader) throws {
    url = try packetReader.readString()
    hash = try packetReader.readString()
  }
}
