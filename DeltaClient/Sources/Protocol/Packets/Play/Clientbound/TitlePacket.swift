//
//  TitlePacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation


struct TitlePacket: ClientboundPacket {
  static let id: Int = 0x4f
  
  var action: TitleAction
  
  enum TitleAction {
    case setTitle(text: ChatComponent)
    case setSubtitle(text: ChatComponent)
    case setActionBar(text: ChatComponent)
    case setTimesAndDisplay(fadeIn: Int, stay: Int, fadeOut: Int)
    case hide
    case reset
  }
  
  init(from packetReader: inout PacketReader) throws {
    let actionId = packetReader.readVarInt()
    switch actionId {
      case 0: // set title
        let text = try packetReader.readChat()
        action = .setTitle(text: text)
      case 1: // set subtitle
        let text = try packetReader.readChat()
        action = .setSubtitle(text: text)
      case 2: // set action bar
        let text = try packetReader.readChat()
        action = .setActionBar(text: text)
      case 3: // set times and display
        let fadeIn = packetReader.readInt()
        let stay = packetReader.readInt()
        let fadeOut = packetReader.readInt()
        action = .setTimesAndDisplay(fadeIn: fadeIn, stay: stay, fadeOut: fadeOut)
      case 4: // hide
        action = .hide
      case 5: // reset
        action = .reset
      default:
        log.debug("invalid title action received")
        action = .reset
    }
  }
}
