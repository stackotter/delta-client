//
//  ServerPinger.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 20/1/21.
//

import Foundation
import os

class ServerPinger: Hashable, ObservableObject {
  var logger: Logger
  var eventManager: EventManager
  var connection: ServerConnection
  
  var info: ServerInfo
  
  @Published var pingInfo: PingInfo? = nil
  
  init(_ serverInfo: ServerInfo) {
    self.eventManager = EventManager()
    self.info = serverInfo
    self.logger = Logger(for: type(of: self))
    self.connection = ServerConnection(host: serverInfo.host, port: serverInfo.port, eventManager: eventManager)
    
    self.connection.registerPacketHandlers(handlers: [
      .status: handleStatusPacket
    ])
  }
  
  func ping() {
    pingInfo = nil
    connection.restart()
    eventManager.registerOneTimeEventHandler({ (event) in
      self.connection.handshake(nextState: .status, callback: {
        let statusRequest = StatusRequest()
        self.connection.sendPacket(statusRequest)
      })
    }, eventName: "connectionReady")
  }
  
  func handleStatusPacket(packetReader: PacketReader) {
    var reader = packetReader
    switch reader.packetId {
      case StatusResponse.id:
        do {
          let packet = try StatusResponse.from(&reader)!
          let json = packet.json
        
          let versionInfo = try json.getJSON(forKey: "version")
          let versionName = try versionInfo.getString(forKey: "name")
          let protocolVersion = try versionInfo.getInt(forKey: "protocol")
          
          let players = try json.getJSON(forKey: "players")
          let maxPlayers = try players.getInt(forKey: "max")
          let numPlayers = try players.getInt(forKey: "online")
          
          let pingInfo = PingInfo(versionName: versionName, protocolVersion: protocolVersion, maxPlayers: maxPlayers, numPlayers: numPlayers, description: "Ping Complete", modInfo: "")
          
          connection.close()
          DispatchQueue.main.sync {
            self.pingInfo = pingInfo
          }
        } catch {
          logger.debug("failed to handle status response: \(error.localizedDescription)")
        }
        
      default:
        return
    }
  }
  
  static func == (lhs: ServerPinger, rhs: ServerPinger) -> Bool {
    return lhs.info == rhs.info
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(info)
  }
}
