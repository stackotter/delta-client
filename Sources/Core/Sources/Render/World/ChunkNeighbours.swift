/// Stores a chunk's neighbours.
///
/// All 4 neighbours must be present.
public struct ChunkNeighbours {
  /// The neighbour chunk to the North.
  public var north: Chunk
  /// The neighbour chunk to the East.
  public var east: Chunk
  /// The neighbour chunk to the South.
  public var south: Chunk
  /// The neighbour chunk to the West.
  public var west: Chunk
  
  public init(north: Chunk, east: Chunk, south: Chunk, west: Chunk) {
    self.north = north
    self.east = east
    self.south = south
    self.west = west
  }
  
  /// Returns the neighbour in the given direction
  public func neighbour(in direction: CardinalDirection) -> Chunk {
    switch direction {
      case .north:
        return north
      case .east:
        return east
      case .south:
        return south
      case .west:
        return west
    }
  }
}
