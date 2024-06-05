/// Something targeted by the player. Often a ``Block``, ``Entity`` or ``Thing``.
public struct Targeted<T> {
  /// The underlying thing getting targeted.
  public var target: T
  /// The distance from the player to the point of intersection.
  public var distance: Float
  /// The face of the bounding box which the player's ray intersects with.
  public var face: Direction
  /// The position at which the player's ray intersects the thing's bounding box.
  public var targetedPosition: Vec3f

  /// The targeted position relative to the block that it's in. All coordinates will be in
  /// the range `0...1`.
  public var cursor: Vec3f {
    var cursor = targetedPosition
    cursor.x = cursor.x.truncatingRemainder(dividingBy: 1)
    cursor.y = cursor.y.truncatingRemainder(dividingBy: 1)
    cursor.z = cursor.z.truncatingRemainder(dividingBy: 1)
    return cursor
  }

  /// Maps the targeted value, useful for changing the representation of the wrapped target.
  public func map<U>(_ mapTarget: (T) -> U) -> Targeted<U> {
    Targeted<U>(
      target: mapTarget(target),
      distance: distance,
      face: face,
      targetedPosition: targetedPosition
    )
  }
}
