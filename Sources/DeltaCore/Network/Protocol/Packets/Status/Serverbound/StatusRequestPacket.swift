//
//  StatusRequestPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

public struct StatusRequestPacket: ServerboundPacket {
  public static let id: Int = 0x00
  
  public func writePayload(to writer: inout PacketWriter) { }
}
