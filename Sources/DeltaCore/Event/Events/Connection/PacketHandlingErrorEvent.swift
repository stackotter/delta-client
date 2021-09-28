//
//  PacketHandlingErrorEvent.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 8/8/21.
//

import Foundation

public struct PacketHandlingErrorEvent: Event {
  public var packetId: Int
  public var error: String
  
  public init(packetId: Int, error: String) {
    self.packetId = packetId
    self.error = error
  }
}
