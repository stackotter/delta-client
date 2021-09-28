//
//  UpdateViewDistancePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

public struct UpdateViewDistancePacket: ClientboundPacket {
  public static let id: Int = 0x41
  
  public var viewDistance: Int

  public init(from packetReader: inout PacketReader) throws {
    viewDistance = packetReader.readVarInt()
  }
}
