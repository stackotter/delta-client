/// Represents a block getting broken. Includes the stage of the breaking animation,
/// the entity breaking the block (the perpetrator), and the position.
public struct BreakingBlock {
  public var position: BlockPosition
  public var perpetratorEntityId: Int
  public var progress: Double

  /// `nil` if the animation hasn't started yet. Otherwise an integer in the range `0...9`.
  public var stage: Int? {
    guard progress >= 0 else {
      return nil
    }

    guard progress <= 1 else {
      return 9
    }

    let stage = Int(progress * 10) - 1
    if stage < 0 {
      return nil
    } else {
      return stage
    }
  }
}
