//
//  OpenSignEditorPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

public struct OpenSignEditorPacket: ClientboundPacket {
  public static let id: Int = 0x2f
  
  public var location: Position
  
  public init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
  }
}
