//
//  StatusResponsePacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation
import os

struct StatusResponsePacket: ClientboundPacket {
  static let id: Int = 0x00
  
  var json: JSON
  
  init(from packetReader: inout PacketReader) throws {
    json = try packetReader.readJSON()
  }
  
  func handle(for serverPinger: ServerPinger) {
    guard
      let versionInfo = json.getJSON(forKey: "version"),
      let versionName = versionInfo.getString(forKey: "name"),
      let protocolVersion = versionInfo.getInt(forKey: "protocol"),
      let players = json.getJSON(forKey: "players"),
      let maxPlayers = players.getInt(forKey: "max"),
      let numPlayers = players.getInt(forKey: "online")
    else {
      Logger.debug("failed to parse status response json")
      return
    }
    
    let pingResult = PingResult(versionName: versionName, protocolVersion: protocolVersion, maxPlayers: maxPlayers, numPlayers: numPlayers, description: "Ping Complete", modInfo: "")
    
    serverPinger.connection.close()
    DispatchQueue.main.sync {
      serverPinger.pingResult = pingResult
    }
  }
}
