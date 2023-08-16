import Foundation

extension Block {
  /// Properties of a block which are specific to each block state (e.g. direction of dispenser).
  public struct StateProperties: Codable {
    /// The direction which the block is facing.
    public var facing: Direction?
    /// Whether the block is open or not (present for blocks such as trapdoors).
    public var isOpen: Bool?

    /// Used for missing blocks.
    public static let `default` = StateProperties(facing: nil, isOpen: nil)
  }
}
