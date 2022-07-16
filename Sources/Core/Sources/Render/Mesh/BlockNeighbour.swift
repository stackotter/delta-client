/// A representation of a neighbouring block that can be used efficiently when generating meshes.
struct BlockNeighbour {
  /// The direction that the neighbouring block is located compared to the block.
  let direction: Direction
  /// If the neighbour is in another chunk, the direction of the chunk containing the neighbour.
  let chunkDirection: CardinalDirection?
  /// The index of the neighbour block in its chunk.
  let index: Int
}
