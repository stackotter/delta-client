//
//  PlayerInfo.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 27/2/21.
//

import Foundation

struct PlayerInfo {
  var uuid: UUID
  var name: String
  var properties: [PlayerProperty]
  var gamemode: Gamemode
  var ping: Int32
  var displayName: ChatComponent?
}
