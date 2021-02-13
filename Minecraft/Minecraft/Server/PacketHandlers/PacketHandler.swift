//
//  PacketHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation

protocol PacketHandler {
  func handlePacket(_ packetReader: PacketReader)
}
