//
//  DisplayScoreboardPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

public struct DisplayScoreboardPacket: ClientboundPacket {
  public static let id: Int = 0x43
  
  public var position: Int8
  public var scoreName: String

  public init(from packetReader: inout PacketReader) throws {
    position = packetReader.readByte()
    scoreName = try packetReader.readString()
  }
}
