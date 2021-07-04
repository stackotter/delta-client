//
//  BlockState.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore

public struct BlockState {
  public var id: Int
  public var blockId: Int
  public var luminance: Int
  public var isRandomlyTicking: Bool
  public var hasSidedTransparency: Bool
  public var soundVolume: Double
  public var soundPitch: Double
  public var breakSound: Int
  public var stepSound: Int
  public var placeSound: Int
  public var hitSound: Int
  public var fallSound: Int
  public var requiresTool: Bool
  public var hardness: Double
  public var isOpaque: Bool
  public var material: Identifier
  public var tintColor: Int
  public var collisionShape: Int
  public var outlineShape: Int
  public var solidRender: Bool?
  public var translucent: Bool?
  public var lightBlock: Int?
  public var largeCollisionShape: Bool?
  public var isCollisionShapeFullBlock: Bool?
  public var occlusionShape: Int?
  public var occlusionShapes: [Int]?
  public var isSturdy: Bool?
}
