//
//  SetCompressionPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

public struct SetCompressionPacket: ClientboundPacket {
  public static let id: Int = 0x03

  public var threshold: Int
  
  public init(from packetReader: inout PacketReader) throws {
    threshold = packetReader.readVarInt()
  }
  
  public func handle(for client: Client) throws {
    client.connection?.setCompression(threshold: threshold)
  }
}
