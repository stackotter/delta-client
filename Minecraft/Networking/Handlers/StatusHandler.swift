//
//  StatusHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

struct StatusHandler: PacketHandler {
  var eventManager: EventManager
  
  func handlePacket(packetReader: PacketReader) {
    switch (packetReader.packetId) {
      case 0x00:
        handle(StatusResponse.from(packetReader)!)
      default:
        return
    }
  }
  
  func handle(_ packet: StatusResponse) {
    let json = packet.json
    
    let versionInfo = json.getJSON(forKey: "version")
    let versionName = versionInfo.getString(forKey: "name")
    let protocolVersion = versionInfo.getInt(forKey: "protocol")
    
    let players = json.getJSON(forKey: "players")
    let maxPlayers = players.getInt(forKey: "max")
    let numPlayers = players.getInt(forKey: "online")
    
    let pingInfo = PingInfo(versionName: versionName, protocolVersion: protocolVersion, maxPlayers: maxPlayers, numPlayers: numPlayers, description: "Ping Complete", modInfo: "")
    eventManager.triggerEvent(event: .pingInfoReceived(pingInfo))
  }
}
