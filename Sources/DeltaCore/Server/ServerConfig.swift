//
//  ServerConfig.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 18/1/21.
//

import Foundation

// holds server config received from the server such as view distance
struct ServerConfig {
  var worldCount: Int
  var worldNames: [Identifier]
  
  var dimensionCodec: NBTCompound // create actual dimension codec struct
  
  var maxPlayers: UInt8
  var viewDistance: Int
  var useReducedDebugInfo: Bool
  var enableRespawnScreen: Bool
  
  // generates a default config for before the join game packet is received
  // maybe there's a better way to deal with this
  static func createDefault() -> ServerConfig {
    return ServerConfig(
      worldCount: 0,
      worldNames: [],
      dimensionCodec: NBTCompound(),
      maxPlayers: 0,
      viewDistance: 0,
      useReducedDebugInfo: false,
      enableRespawnScreen: false
    )
  }
}
