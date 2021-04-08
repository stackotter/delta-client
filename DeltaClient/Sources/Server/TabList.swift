//
//  TabList.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 27/2/21.
//

import Foundation

struct TabList {
  var players: [UUID: PlayerInfo] = [:]
  
  init() {}
  
  mutating func addPlayer(_ playerInfo: PlayerInfo) {
    players[playerInfo.uuid] = playerInfo
  }
  
  mutating func updateGamemode(_ gamemode: Gamemode, uuid: UUID) {
    players[uuid]?.gamemode = gamemode
  }
  
  mutating func updateLatency(_ ping: Int, uuid: UUID) {
    players[uuid]?.ping = ping
  }
  
  mutating func updateDisplayName(_ displayName: ChatComponent?, uuid: UUID) {
    players[uuid]?.displayName = displayName
  }
  
  mutating func removePlayer(uuid: UUID) {
    players.removeValue(forKey: uuid)
  }
}
