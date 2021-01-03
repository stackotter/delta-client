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
    do {
      switch (packetReader.packetId) {
        case 0x00:
          handle(try StatusResponse.from(packetReader)!)
        default:
          return
      }
    } catch {
      eventManager.triggerError("failed to handle status packet with packet id: \(packetReader.packetId)")
    }
  }
  
  func handle(_ packet: StatusResponse) {
    let json = packet.json
    
    do {
      let versionInfo = try json.getJSON(forKey: "version")
      let versionName = try versionInfo.getString(forKey: "name")
      let protocolVersion = try versionInfo.getInt(forKey: "protocol")
      
      let players = try json.getJSON(forKey: "players")
      let maxPlayers = try players.getInt(forKey: "max")
      let numPlayers = try players.getInt(forKey: "online")
      
      let pingInfo = PingInfo(versionName: versionName, protocolVersion: protocolVersion, maxPlayers: maxPlayers, numPlayers: numPlayers, description: "Ping Complete", modInfo: "")
      eventManager.triggerEvent(event: .pingInfoReceived(pingInfo))
    } catch {
      eventManager.triggerError("failed to handle status response json")
    }
  }
}
