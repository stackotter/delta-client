//
//  OpenWindowPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

public struct OpenWindowPacket: ClientboundPacket {
  public static let id: Int = 0x2e
  
  public var windowId: Int
  public var windowType: Int
  public var windowTitle: ChatComponent
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readVarInt()
    windowType = packetReader.readVarInt()
    windowTitle = try packetReader.readChat()
  }
}
