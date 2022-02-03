import Foundation

/// Metadata about a block.
public struct BlockEntity {
  /// The position of the block that this metadata applies to.
  public let position: Position
  /// Identifier of the block that this metadata is for.
  public let identifier: Identifier
  /// Metadata stored in the nbt format.
  public let nbt: NBT.Compound
}
