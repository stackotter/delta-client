//
//  LoginDisconnectPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

public struct LoginDisconnectPacket: ClientboundPacket {
  public static let id: Int = 0x00
  
  public var reason: ChatComponent
  
  public init(from packetReader: inout PacketReader) throws {
    reason = try packetReader.readChat()
  }
  
  public func handle(for client: Client) {
    log.trace("Disconnected from server: \(reason.toText())")
    client.eventBus.dispatch(LoginDisconnectEvent(reason: reason.toText()))
  }
}
