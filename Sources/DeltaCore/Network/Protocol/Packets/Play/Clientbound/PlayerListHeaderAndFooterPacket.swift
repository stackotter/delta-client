//
//  PlayerListHeaderAndFooterPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

public struct PlayerListHeaderAndFooterPacket: ClientboundPacket {
  public static let id: Int = 0x53
  
  public var header: ChatComponent
  public var footer: ChatComponent

  public init(from packetReader: inout PacketReader) throws {
    header = try packetReader.readChat()
    footer = try packetReader.readChat()
  }
}
