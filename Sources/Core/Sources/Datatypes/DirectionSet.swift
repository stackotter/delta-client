/// A set of directions.
public struct DirectionSet: SetAlgebra {
  public typealias Element = Direction

  public var rawValue: UInt8

  public static let north = DirectionSet(containing: .north)
  public static let south = DirectionSet(containing: .south)
  public static let east = DirectionSet(containing: .east)
  public static let west = DirectionSet(containing: .west)
  public static let up = DirectionSet(containing: .up)
  public static let down = DirectionSet(containing: .down)

  /// The set of all directions.
  public static let all: DirectionSet = [
    .north,
    .south,
    .east,
    .west,
    .up,
    .down
  ]

  public var isEmpty: Bool {
    return rawValue == 0
  }

  public init() {
    rawValue = 0
  }

  public init(rawValue: UInt8) {
    self.rawValue = rawValue
  }

  public init(containing direction: Direction) {
    rawValue = Self.directionMask(direction)
  }

  public init<S: Sequence>(_ sequence: S) where S.Element == Direction {
    self.init()
    for element in sequence {
      insert(element)
    }
  }

  private static func directionMask(_ direction: Direction) -> UInt8 {
    return 1 << direction.rawValue
  }

  public func contains(_ direction: Direction) -> Bool {
    return rawValue & Self.directionMask(direction) != 0
  }

  @discardableResult public mutating func insert(_ direction: Direction) -> (inserted: Bool, memberAfterInsert: Direction) {
    let oldRawValue = rawValue
    rawValue |= Self.directionMask(direction)
    return (inserted: oldRawValue != rawValue, memberAfterInsert: direction)
  }

  @discardableResult public mutating func update(with direction: Direction) -> Direction? {
    let oldRawValue = rawValue
    rawValue |= Self.directionMask(direction)
    return oldRawValue == rawValue ? nil : direction
  }

  @discardableResult public mutating func remove(_ direction: Direction) -> Direction? {
    let oldRawValue = rawValue
    rawValue &= ~Self.directionMask(direction)
    return oldRawValue == rawValue ? nil : direction
  }

  public func union(_ other: DirectionSet) -> DirectionSet {
    return DirectionSet(rawValue: rawValue | other.rawValue)
  }

  public mutating func formUnion(_ other: DirectionSet) {
    rawValue |= other.rawValue
  }

  public func intersection(_ other: DirectionSet) -> DirectionSet {
    return DirectionSet(rawValue: rawValue & other.rawValue)
  }

  public mutating func formIntersection(_ other: DirectionSet) {
    rawValue &= other.rawValue
  }

  public func symmetricDifference(_ other: DirectionSet) -> DirectionSet {
    return DirectionSet(rawValue: rawValue ^ other.rawValue)
  }

  public mutating func formSymmetricDifference(_ other: DirectionSet) {
    rawValue ^= other.rawValue
  }

  public func isStrictSubset(of other: DirectionSet) -> Bool {
    return rawValue != other.rawValue && intersection(other).rawValue == rawValue
  }

  public func isStrictSuperset(of other: DirectionSet) -> Bool {
    return other.isStrictSubset(of: self)
  }

  public func isDisjoint(with other: DirectionSet) -> Bool {
    return subtracting(other).rawValue == rawValue
  }

  public func isSubset(of other: DirectionSet) -> Bool {
    return intersection(other).rawValue == rawValue
  }

  public func isSuperset(of other: DirectionSet) -> Bool {
    return other.isSubset(of: self)
  }

  public mutating func subtract(_ other: DirectionSet) {
    rawValue &= ~other.rawValue
  }

  public func subtracting(_ other: DirectionSet) -> DirectionSet {
    return DirectionSet(rawValue: rawValue & (~other.rawValue))
  }
}
