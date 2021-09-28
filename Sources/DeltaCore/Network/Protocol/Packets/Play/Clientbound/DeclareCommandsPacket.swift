//
//  DeclareCommandsPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct DeclareCommandsPacket: ClientboundPacket {
  public static let id: Int = 0x11
  
  public init(from packetReader: inout PacketReader) throws {
    // IMPLEMENT: declare commands packet
  }
}
