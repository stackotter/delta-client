//
//  StatusHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation
import os

struct StatusHandler: PacketHandler {
  var serverPinger: ServerPinger
  
  init(serverPinger: ServerPinger) {
    self.serverPinger = serverPinger
  }
  
  func handlePacket(_ packetReader: PacketReader) {
    var reader = packetReader
    switch reader.packetId {
      case StatusResponse.id:
        do {
          let packet = try StatusResponse(fromReader: &reader)
          let json = packet.json
          
          let versionInfo = try json.getJSON(forKey: "version")
          let versionName = try versionInfo.getString(forKey: "name")
          let protocolVersion = try versionInfo.getInt(forKey: "protocol")
          
          let players = try json.getJSON(forKey: "players")
          let maxPlayers = try players.getInt(forKey: "max")
          let numPlayers = try players.getInt(forKey: "online")
          
          let pingInfo = PingInfo(versionName: versionName, protocolVersion: protocolVersion, maxPlayers: maxPlayers, numPlayers: numPlayers, description: "Ping Complete", modInfo: "")
          
          serverPinger.connection.close()
          DispatchQueue.main.sync {
            self.serverPinger.pingInfo = pingInfo
          }
        } catch {
          Logger.debug("failed to handle status response: \(error.localizedDescription)")
        }
        
      default:
        return
    }
  }
}
