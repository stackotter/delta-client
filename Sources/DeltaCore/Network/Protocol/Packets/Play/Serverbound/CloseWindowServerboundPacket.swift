//
//  CloseWindowServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct CloseWindowServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x0a
  
  public var windowId: UInt8
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(windowId)
  }
}
