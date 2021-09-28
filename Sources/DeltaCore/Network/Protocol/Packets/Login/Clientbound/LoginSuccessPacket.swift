//
//  LoginSuccessPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

public struct LoginSuccessPacket: ClientboundPacket {
  public static let id: Int = 0x02
  
  public var uuid: UUID
  public var username: String
  
  public init(from packetReader: inout PacketReader) throws {
    uuid = try packetReader.readUUID()
    username = try packetReader.readString()
  }
  
  public func handle(for client: Client) throws {
    client.connection?.setState(.play)
  }
}
