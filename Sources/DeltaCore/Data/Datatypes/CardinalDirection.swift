//
//  CardinalDirection.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/3/21.
//

import Foundation

public enum CardinalDirection {
  case north
  case east
  case south
  case west
  
  // TODO: use case iterable instead
  public static var allDirections: [CardinalDirection] = [
    .north,
    .east,
    .south,
    .west]
  
  public var opposite: CardinalDirection {
    let oppositeMap: [CardinalDirection: CardinalDirection] = [
      .north: .south,
      .south: .north,
      .east: .west,
      .west: .east]
    return oppositeMap[self]!
  }
}
