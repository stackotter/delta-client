import Collections

/// A graph structure used to determine which chunk sections are visible from a given camera.
///
/// It uses a conservative approach, which means that some chunks will be incorrectly identified
/// as visible, but no chunks will be incorrectly identified as not visible.
public struct VisibilityGraph {
  // MARK: Public properties
  
  /// Number of sections in the graph.
  public var sectionCount: Int {
    lock.acquireReadLock()
    defer { lock.unlock() }
    return sectionFaceConnectivity.count
  }
  
  // MARK: Private properties
  
  /// Used to make the graph threadsafe.
  private var lock = ReadWriteLock()
  /// Stores the connectivity each chunk in the graph (see `ChunkSectionFaceConnectivity`).
  private var sectionFaceConnectivity: [ChunkSectionPosition: ChunkSectionFaceConnectivity] = [:]
  /// All of the chunks currently in the visibility graph.
  private var chunks: Set<ChunkPosition> = []
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
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    chunks.insert(position)
    
    for (sectionY, section) in chunk.getSections().enumerated() {
      let sectionPosition = ChunkSectionPosition(position, sectionY: sectionY)
      var connectivityGraph = ChunkSectionVoxelGraph(for: section, blockModelPalette: blockModelPalette)
      sectionFaceConnectivity[sectionPosition] = connectivityGraph.calculateConnectivity()
    }
  }
  
  /// Removes the given chunk from the visibility graph.
  /// - Parameter position: The position of the chunk to remove.
  public mutating func removeChunk(at position: ChunkPosition) {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    chunks.remove(position)
    
    for y in 0..<Chunk.numSections {
      sectionFaceConnectivity.removeValue(forKey: ChunkSectionPosition(position, sectionY: y))
    }
  }
  
  /// Updates a chunk in the visibility graph.
  /// - Parameters:
  ///   - chunk: Chunk to update.
  ///   - position: Position of chunk to update.
  public mutating func updateChunk(_ chunk: Chunk, at position: ChunkPosition) {
    addChunk(chunk, at: position)
  }
  
  /// Gets whether the visibility graph contains the given chunk.
  /// - Parameter position: The position of the chunk to check.
  public func containsChunk(at position: ChunkPosition) -> Bool {
    lock.acquireReadLock()
    defer { lock.unlock() }
    
    return chunks.contains(position)
  }
  
  /// Gets whether a ray could possibly pass through the given chunk section, entering through a given face and exiting out another given face.
  /// - Parameters:
  ///   - entryFace: Face to enter through.
  ///   - exitFace: Face to exit through.
  ///   - section: Section to check for.
  ///   - acquireLock: Whether to acquire a read lock or not. Only set to `false` if you know what you're doing.
  /// - Returns: Whether is it possibly to see through the section looking through `entryFace` and out `exitFace`.
  public func canPass(from entryFace: Direction, to exitFace: Direction, through section: ChunkSectionPosition, acquireLock: Bool = true) -> Bool {
    // TODO: return true if section is 1 section above the world and the player is above the world (and same for below)
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    let first = ChunkSectionFace.forDirection(entryFace)
    let second = ChunkSectionFace.forDirection(exitFace)
    return sectionFaceConnectivity[section]?.areConnected(first, second) == true
  }
  
  /// Gets the positions of all chunk sections that are possibly visible from the given chunk.
  /// - Parameter position: Position of the chunk section that the world is being viewed from.
  /// - Parameter camera: Used for frustum culling.
  /// - Returns: The positions of all possibly visible chunk sections. Does not include empty sections.
  public func chunkSectionsVisible(from position: ChunkSectionPosition, camera: Camera) -> [ChunkSectionPosition] {
    lock.acquireReadLock()
    defer { lock.unlock() }
    
    var visible: [ChunkSectionPosition] = [position]
    visible.reserveCapacity(sectionCount)
    var visited = Set<ChunkSectionPosition>(minimumCapacity: sectionCount)
    var queue: Deque = [SearchQueueEntry(position: position, entryFace: nil, directions: [])]
    
    while let current = queue.popFirst() {
      let entryFace = current.entryFace
      let position = current.position
      
      for exitFace in Direction.allDirections where exitFace != entryFace {
        guard let neighbourPosition = position.neighbour(inDirection: exitFace) else {
          continue
        }
        
        // Avoids doubling back. If a chunk has been exited from the top face, any chunks after that shouldn't be exited from the bottom face.
        if current.directions.contains(DirectionSet.member(exitFace.opposite)) {
          continue
        }
        
        // Don't visit the same section twice
        guard !visited.contains(neighbourPosition) else {
          continue
        }
        
        if let entryFace = entryFace, !canPass(from: entryFace, to: exitFace, through: position, acquireLock: false) {
          continue
        }
        
        if !camera.isChunkSectionVisible(at: neighbourPosition) {
          continue
        }
        
        visited.insert(neighbourPosition)
        
        var directions = current.directions
        directions.insert(DirectionSet.member(exitFace))
        
        queue.append(SearchQueueEntry(
          position: neighbourPosition,
          entryFace: exitFace.opposite,
          directions: directions))
        
        visible.append(neighbourPosition)
      }
    }
    
    return visible
  }
}
