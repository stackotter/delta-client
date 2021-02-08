//
//  WorldConfig.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 18/1/21.
//

import Foundation

struct WorldConfig {
  var worldName: Identifier
  var dimension: Identifier
  var hashedSeed: Int64
  var isDebug: Bool
  var isFlat: Bool
}
