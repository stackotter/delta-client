import DequeModule
public struct VisibilityGraph {
  // MARK: Private properties
  
  /// Connectivity of faces of each chunk in the graph.
  private var sectionFaceConnectivity: [ChunkSectionPosition: [Direction: Set<Direction>]] = [:]
  /// Used to read and write `sectionFaceConnectivity` in a thread same manner.
  private var lock = ReadWriteLock()
  
  /// Block model palette used to determine whether blocks are see through or not.
  private let blockModelPalette: BlockModelPalette
  
  // MARK: Init
  
  /// Creates an empty visibility graph.
  /// - Parameter blockModelPalette: Used to determine whether blocks are see through or not.
  public init(blockModelPalette: BlockModelPalette) {
    self.blockModelPalette = blockModelPalette
  }
  
  // MARK: Public methods
  
  /// Adds a chunk to the visibility graph.
  /// - Parameters:
  ///   - chunk: Chunk to add.
  ///   - position: Position of chunk.
  public mutating func addChunk(_ chunk: Chunk, at position: ChunkPosition) {
    var connectivity: [ChunkSectionPosition: [Direction: Set<Direction>]] = [:]
    for (sectionY, section) in chunk.getSections().enumerated() {
      let connectivityGraph = ChunkSectionVoxelGraph(for: section, modelPalette: blockModelPalette)
      connectivity[ChunkSectionPosition(position, sectionY: sectionY)] = connectivityGraph.calculateConnectivity()
    }
    
    lock.acquireWriteLock()
    defer { lock.unlock() }
    for (position, sectionConnectivity) in connectivity {
      sectionFaceConnectivity[position] = sectionConnectivity
    }
  }
  
  /// Updates a chunk in the visibility graph.
  /// - Parameters:
  ///   - chunk: Chunk to update.
  ///   - position: Position of chunk to update.
  public mutating func updateChunk(_ chunk: Chunk, at position: ChunkPosition) {
    addChunk(chunk, at: position)
  }
  
  /// Gets whether a ray could possibly pass through the given chunk section, entering through a given face and exiting out another given face.
  /// - Parameters:
  ///   - entryFace: Face to enter through.
  ///   - exitFace: Face to exit through.
  ///   - section: Section to check for.
  /// - Returns: Whether is it possibly to see through the section looking through `entryFace` and out `exitFace`.
  public func canPass(from entryFace: Direction, to exitFace: Direction, through section: ChunkSectionPosition) -> Bool {
    lock.acquireReadLock()
    defer { lock.unlock() }
    return sectionFaceConnectivity[section][entryFace]?.contains(exitFace)
  }
  
  /// Gets the positions of all chunk sections that are possibly visible from the given chunk.
  /// - Parameter position: Position of the chunk that the world is being viewed from.
  /// - Returns: The positions of all possibly visible chunk sections.
  public func chunkSectionsVisible(from position: ChunkPosition, camera: Camera) -> [ChunkSectionPosition] {
    var discovered: Set<ChunkSectionPosition> = [position]
    var queue: Deque<(ChunkSectionPosition, Direction?, Set<Direction>)> = [(position, nil)]
    
    var visible: [ChunkSectionPosition] = []
    
    var cameraDirectionVector = camera.directionVector
    
    while !queue.isEmpty {
      if let item = queue.popFirst() {
        let position = item.0
        let entryFace = item.1
        let directionsTravelled = item.2
        
        // Mark as visible
        visible.append(position)
        
        // Add neighbours to queue
        for exitFace in Direction.allDirections where exitFace != entryFace {
          // Make sure the sections don't get processed twice
          let neighbour = position.neighbour(inDirection: exitFace)
          if discovered.contains(neighbour) {
            return
          }
          discovered.insert(neighbour)
          
          // Check that it is possible to
          if let entryFace = entryFace {
            if canPass(from: entryFace, to: exitFace, through: position) {
              queue.append(neighbour)
            }
          } else {
            queue.append(neighbour)
          }
        }
      }
    }
    
    return visible
  }
}
