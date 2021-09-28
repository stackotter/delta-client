//
//  LightLevel.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 6/6/21.
//

import Foundation

public struct LightLevel {
  public static var defaultBlockLightLevel = 0
  public static var defaultSkyLightLevel = 0
  
  public var sky: Int
  public var block: Int
  
  public init(sky: Int, block: Int) {
    self.sky = sky
    self.block = block
  }
  
  public init() {
    sky = Self.defaultSkyLightLevel
    block = Self.defaultBlockLightLevel
  }
  
  public static func max(_ a: LightLevel, _ b: LightLevel) -> LightLevel {
    return LightLevel(sky: Swift.max(a.sky, b.sky), block: Swift.max(a.block, b.block))
  }
}
