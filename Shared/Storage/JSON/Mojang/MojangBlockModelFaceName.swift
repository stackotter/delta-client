//
//  MojangBlockModelFaceName.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore

/// An enum used when decoding Mojang formatted block models from JSON.
public enum MojangBlockModelFaceName: String, Codable {
  case down
  case up
  case north
  case south
  case west
  case east
  
  var direction: Direction {
    switch self {
      case .down:
        return .down
      case .up:
        return .up
      case .north:
        return .north
      case .south:
        return .south
      case .west:
        return .west
      case .east:
        return .east
    }
  }
}
