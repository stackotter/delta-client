//
//  AcknowledgePlayerDiggingPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct AcknowledgePlayerDiggingPacket: ClientboundPacket {
  public static let id: Int = 0x07
  
  public var location: Position
  public var block: Int
  public var status: Int
  public var successful: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
    block = packetReader.readVarInt()
    status = packetReader.readVarInt()
    successful = packetReader.readBool()
  }
}
