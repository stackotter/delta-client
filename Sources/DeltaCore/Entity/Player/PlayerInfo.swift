//
//  PlayerInfo.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 27/2/21.
//

import Foundation

public struct PlayerInfo {
  public var uuid: UUID
  public var name: String
  public var properties: [PlayerProperty]
  public var gamemode: Gamemode
  public var ping: Int
  public var displayName: ChatComponent?
}
