//
//  StatusHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation
import os

enum StatusResponseError: LocalizedError {
  case invalidJSON
}

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
          
          guard let versionInfo = json.getJSON(forKey: "version"),
            let versionName = versionInfo.getString(forKey: "name"),
            let protocolVersion = versionInfo.getInt(forKey: "protocol"),
            let players = json.getJSON(forKey: "players"),
            let maxPlayers = players.getInt(forKey: "max"),
            let numPlayers = players.getInt(forKey: "online")
          else {
            throw StatusResponseError.invalidJSON
          }
          
          let pingInfo = PingInfo(versionName: versionName, protocolVersion: protocolVersion, maxPlayers: maxPlayers, numPlayers: numPlayers, description: "Ping Complete", modInfo: "")
          
          serverPinger.test.close()
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
