//
//  PacketHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 23/12/20.
//

import Foundation

protocol PacketHandler {
  var eventManager: EventManager { get }
  
  func handlePacket(reader: PacketReader)
}
