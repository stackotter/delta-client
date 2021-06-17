//
//  AdvancementTabPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct AdvancementTabPacket: ServerboundPacket {
  static let id: Int = 0x21
  
  var action: AdvancementTabAction
  
  enum AdvancementTabAction {
    case openedTab(tabId: Identifier)
    case closedScreen
  }
  
  func writePayload(to writer: inout PacketWriter) {
    switch action {
      case let .openedTab(tabId: tabId):
        writer.writeVarInt(0) // opened tab
        writer.writeIdentifier(tabId)
      case .closedScreen:
        writer.writeVarInt(1) // closed screen
    }
  }
}
