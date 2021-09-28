//
//  Resources.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 16/7/21.
//

import Foundation

extension ResourcePack {
  public struct Resources {
    public var blockTexturePalette = TexturePalette()
    public var blockModelPalette = BlockModelPalette()
    public var locales: [String: MinecraftLocale] = [:]
  }
}
