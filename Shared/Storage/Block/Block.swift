//
//  Block.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore

public struct Block {
  public var id: Int
  public var explosionResistance: Double
  public var item: Int
  public var friction: Double
  public var velocityMultiplier: Double
  public var jumpVelocityMultiplier: Double
  public var defaultState: Int
  public var hasDynamicShape: Bool
  public var `class`: String
  public var stillFluid: Int?
  public var flowFluid: Int?
  public var fluid: Int?
  public var offsetType: String?
  public var lavaParticles: Bool
  public var flameParticle: Bool
  public var tint: Identifier?
  public var tintColor: Int?
  public var states: [Int]
}
