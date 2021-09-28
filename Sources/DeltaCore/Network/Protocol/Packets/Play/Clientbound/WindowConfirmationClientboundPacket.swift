//
//  WindowConfirmationClientboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct WindowConfirmationClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x12
  
  public var windowId: Int8
  public var actionNumber: Int16
  public var accepted: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readByte()
    actionNumber = packetReader.readShort()
    accepted = packetReader.readBool()
  }
}
