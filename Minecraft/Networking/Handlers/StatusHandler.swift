//
//  StatusHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation

struct StatusHandler {
  var pingCallback: ((PingInfo) -> Void)?
  
  func handlePacket(reader: PacketReader) {
    var mutableReader = reader
    let packetId = mutableReader.readPacketId()
    switch (packetId) {
      case 0x00:
        handle(StatusResponse.from(mutableReader)!)
      default:
        return
    }
  }
  
  func handle(_ packet: StatusResponse) {
    if (pingCallback != nil) {
      let json = packet.json
      
      let versionInfo = json.getJSON(forKey: "version")
      let versionName = versionInfo.getString(forKey: "name")
      let protocolVersion = versionInfo.getInt(forKey: "protocol")
      
      let players = json.getJSON(forKey: "players")
      let maxPlayers = players.getInt(forKey: "max")
      let numPlayers = players.getInt(forKey: "online")
      
      pingCallback!(PingInfo(versionName: versionName, protocolVersion: protocolVersion, maxPlayers: maxPlayers, numPlayers: numPlayers, description: "Ping Complete", modInfo: ""))
    }
  }
}
