import DeltaCore

/// A representation of a neighbouring block that can be used efficiently when generating meshes.
struct BlockNeighbour {
  /// The direction that the neighbouring block is located compared to the block.
  let direction: Direction
  /// If the neighbour is in another chunk,
  /// the direction of the chunk containing the neighbour.
  let chunkDirection: CardinalDirection?
  /// The index of the neighbour block in its chunk.
  let index: Int

  /// Gets the locations of all blocks neighbouring a given block.
  /// - Parameters:
  ///   - index: Block index relative the block's chunk section.
  ///   - sectionIndex: The index of the section that the block is in.
  /// - Returns: The block's neighbours.
  static func neighbours(
    ofBlockAt index: Int,
    inSection sectionIndex: Int
  ) -> [BlockNeighbour] {
    let indexInChunk = index &+ sectionIndex &* Chunk.Section.numBlocks
    var neighbours: [BlockNeighbour] = []
    neighbours.reserveCapacity(6)

    let indexInLayer = indexInChunk % Chunk.blocksPerLayer
    if indexInLayer >= Chunk.width {
      neighbours.append(BlockNeighbour(
        direction: .north,
        chunkDirection: nil,
        index: indexInChunk &- Chunk.width
      ))
    } else {
      neighbours.append(BlockNeighbour(
        direction: .north,
        chunkDirection: .north,
        index: indexInChunk + Chunk.blocksPerLayer - Chunk.width
      ))
    }

    if indexInLayer < Chunk.blocksPerLayer &- Chunk.width {
      neighbours.append(BlockNeighbour(
        direction: .south,
        chunkDirection: nil,
        index: indexInChunk &+ Chunk.width
      ))
    } else {
      neighbours.append(BlockNeighbour(
        direction: .south,
        chunkDirection: .south,
        index: indexInChunk - Chunk.blocksPerLayer + Chunk.width
      ))
    }

    let indexInRow = indexInChunk % Chunk.width
    if indexInRow != Chunk.width &- 1 {
      neighbours.append(BlockNeighbour(
        direction: .east,
        chunkDirection: nil,
        index: indexInChunk &+ 1
      ))
    } else {
      neighbours.append(BlockNeighbour(
        direction: .east,
        chunkDirection: .east,
        index: indexInChunk &- 15
      ))
    }

    if indexInRow != 0 {
      neighbours.append(BlockNeighbour(
        direction: .west,
        chunkDirection: nil,
        index: indexInChunk &- 1
      ))
    } else {
      neighbours.append(BlockNeighbour(
        direction: .west,
        chunkDirection: .west,
        index: indexInChunk &+ 15
      ))
    }

    if indexInChunk < Chunk.numBlocks &- Chunk.blocksPerLayer {
      neighbours.append(BlockNeighbour(
        direction: .up,
        chunkDirection: nil,
        index: indexInChunk &+ Chunk.blocksPerLayer
      ))

      if indexInChunk >= Chunk.blocksPerLayer {
        neighbours.append(BlockNeighbour(
          direction: .down,
          chunkDirection: nil,
          index: indexInChunk &- Chunk.blocksPerLayer
        ))
      }
    }

    return neighbours
  }
}
