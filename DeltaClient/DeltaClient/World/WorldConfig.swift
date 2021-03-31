//
//  WorldConfig.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 18/1/21.
//

import Foundation
import os

struct WorldConfig {
  var worldName: Identifier
  var dimension: Identifier
  var hashedSeed: Int
  var isDebug: Bool
  var isFlat: Bool
  
  static func createDefault() -> WorldConfig {
    Logger.debug("created default world config. this is a sign that a world was accessed before it existed")
    return WorldConfig(
      worldName: Identifier(name: ""),
      dimension: Identifier(name: ""),
      hashedSeed: 0,
      isDebug: false,
      isFlat: false
    )
  }
}
