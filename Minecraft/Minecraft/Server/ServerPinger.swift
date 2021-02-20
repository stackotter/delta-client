//
//  ServerPinger.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/1/21.
//

import Foundation
import os

class ServerPinger: Hashable, ObservableObject {
  var eventManager: EventManager
  var connection: ServerConnection
  var packetRegistry: PacketRegistry
  
  var info: ServerInfo
  
  @Published var pingInfo: PingInfo? = nil
  
  init(_ serverInfo: ServerInfo) {
    self.eventManager = EventManager()
    self.info = serverInfo
    self.connection = ServerConnection(host: serverInfo.host, port: serverInfo.port, eventManager: eventManager, locale: MinecraftLocale.empty())
    self.packetRegistry = PacketRegistry.createDefault()
    self.connection.setHandler(handlePacket)
  }
  
  func handlePacket(_ packetReader: PacketReader, _ state: PacketState) {
    var reader = packetReader
    do {
      try packetRegistry.handlePacket(&reader, forServerPinger: self, inState: state)
    } catch {
      Logger.debug("failed to handle status packet")
    }
  }
  
  func ping() {
    pingInfo = nil
    connection.restart()
    eventManager.registerOneTimeEventHandler({ (event) in
      self.connection.handshake(nextState: .status, callback: {
        let statusRequest = StatusRequestPacket()
        self.connection.sendPacket(statusRequest)
      })
    }, eventName: "connectionReady")
  }
  
  static func == (lhs: ServerPinger, rhs: ServerPinger) -> Bool {
    return lhs.info == rhs.info
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(info)
  }
}
