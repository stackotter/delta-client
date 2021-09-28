//
//  PluginMessagePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation

public struct PluginMessagePacket: ClientboundPacket {
  public static var id: Int = 0x18
  
  public var pluginMessage: PluginMessage
  
  // TODO: Give this its own file and probably specify that it's a mojang plugin not a delta client one.
  public struct PluginMessage {
    public var channel: Identifier
    public var data: Buffer
  }
  
  public init(from packetReader: inout PacketReader) throws {
    let channel = try packetReader.readIdentifier()
    let data = packetReader.buffer
    pluginMessage = PluginMessage(channel: channel, data: data)
  }
  
  public func handle(for client: Client) throws {
    log.debug("plugin message received with channel: \(pluginMessage.channel)")
  }
}
