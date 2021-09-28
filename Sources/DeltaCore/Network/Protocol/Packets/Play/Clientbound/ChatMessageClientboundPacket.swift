//
//  ChatMessageClientboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct ChatMessageClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x0e
  
  public var message: ChatComponent
  public var position: Int8
  public var sender: UUID
  
  public init(from packetReader: inout PacketReader) throws {
    message = try packetReader.readChat()
    position = packetReader.readByte()
    sender = try packetReader.readUUID()
  }
  
  public func handle(for client: Client) throws {
    log.info("Chat message received: \(message.toText())")
  }
}
