//
//  PacketHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation

// TODO: remove if not used
protocol PacketHandler {
  func handlePacket(_ packetReader: PacketReader)
}
