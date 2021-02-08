//
//  ServerConfig.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 18/1/21.
//

import Foundation

// holds server config received from the server such as view distance
struct ServerConfig {
  var worldCount: Int32
  var worldNames: [Identifier]
  
  var dimensionCodec: NBTCompound // create actual dimension codec struct
  
  var maxPlayers: UInt8
  var viewDistance: Int32
  var useReducedDebugInfo: Bool
  var enableRespawnScreen: Bool
}
