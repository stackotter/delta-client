//
//  WorldConfig.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 18/1/21.
//

import Foundation

struct WorldConfig {
  var worldName: Identifier
  // TODO: make an actual dimension object cause nbt is annoying and slower for repeated access than a struct
  var dimension: NBTCompound
  var hashedSeed: Int64
  var isDebug: Bool
  var isFlat: Bool
}
