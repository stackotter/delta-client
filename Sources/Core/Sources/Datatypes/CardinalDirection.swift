import Foundation

/// An axis aligned compass direction (i.e. either North, East, South or West).
public enum CardinalDirection: CaseIterable {
  case north
  case east
  case south
  case west

  /// The opposite direction.
  public var opposite: CardinalDirection {
    let oppositeMap: [CardinalDirection: CardinalDirection] = [
      .north: .south,
      .south: .north,
      .east: .west,
      .west: .east]
    return oppositeMap[self]!
  }
}
