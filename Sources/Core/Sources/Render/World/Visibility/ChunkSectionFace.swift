/// Used by ``ChunkSectionFaceConnectivity`` to efficiently identify pairs of faces.
///
/// If the values of any two faces are added together, the result is a unique integer
/// that represents that pair of faces.
///
/// ``ChunkSectionFaceConnectivity`` uses this property to efficiently store/access
/// whether a given pair of faces is connected. A bit field is used where the value
/// for each pair is the offset of a bit representing whether those two faces are
/// connected.
///
/// Its cases are in the same order as ``DirectionSet``.
public enum ChunkSectionFace: Int, CaseIterable {
  case north = 0
  case south = 1
  case east = 2
  case west = 4
  case up = 7
  case down = 12
  
  public static func forDirection(_ direction: Direction) -> ChunkSectionFace {
    switch direction {
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
