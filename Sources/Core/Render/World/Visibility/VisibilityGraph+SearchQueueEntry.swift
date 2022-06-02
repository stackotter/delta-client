extension VisibilityGraph {
  /// An entry in the breadth-first-search queue. Used when traversing a ``VisibilityGraph`` in ``chunkSectionsVisible(from:camera:)``.
  struct SearchQueueEntry {
    let position: ChunkSectionPosition
    let entryFace: Direction?
    let directions: DirectionSet
  }
}
