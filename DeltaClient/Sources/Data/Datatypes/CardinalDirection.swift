//
//  CardinalDirection.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/3/21.
//

import Foundation

enum CardinalDirection {
  case north
  case east
  case south
  case west
  
  static var allDirections: [CardinalDirection] = [
    .north,
    .east,
    .south,
    .west]
  
  var opposite: CardinalDirection {
    let oppositeMap: [CardinalDirection: CardinalDirection] = [
      .north: .south,
      .south: .north,
      .east: .west,
      .west: .east]
    return oppositeMap[self]!
  }
}
