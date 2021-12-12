import Collections

/// A graph structure used to determine which chunk sections are visible from a given camera.
///
/// It uses a conservative approach, which means that some chunks will be incorrectly identified as visible, but no chunks will be incorrectly identified as not visible.
public struct VisibilityGraph {
  // MARK: Public properties
  
  /// Number of sections in the graph.
  public var sectionCount: Int {
    lock.acquireReadLock()
    defer { lock.unlock() }
    
    return sectionFaceConnectivity.count
  }
  
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
      var connectivityGraph = ChunkSectionVoxelGraph(for: section, blockModelPalette: blockModelPalette)
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
    return sectionFaceConnectivity[section]?[entryFace]?.contains(exitFace) == true
  }
  
  // TODO: move these two structs (DirectionSet and SearchQueueEntry)
  
  struct DirectionSet: OptionSet {
    public let rawValue: UInt8
    
    init(rawValue: UInt8) {
      self.rawValue = rawValue
    }
    
    static let north = DirectionSet(rawValue: 0x01)
    static let east = DirectionSet(rawValue: 0x02)
    static let south = DirectionSet(rawValue: 0x04)
    static let west = DirectionSet(rawValue: 0x08)
    static let up = DirectionSet(rawValue: 0x16)
    static let down = DirectionSet(rawValue: 0x32)
    
    static func member(_ direction: Direction) -> DirectionSet {
      switch direction {
        case .down:
          return .down
        case .up:
          return .up
        case .north:
          return .north
        case .south:
          return .south
        case .west:
          return .west
        case .east:
          return .east
      }
    }
  }
  
  struct SearchQueueEntry {
    let position: ChunkSectionPosition
    let entryFace: Direction?
    let directions: DirectionSet
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
          log.debug("Skip neighbour that would be going backwards")
          continue
        }
        
        // Don't visit the same section twice
        guard !visited.contains(neighbourPosition) else {
          log.debug("Already visited")
          continue
        }
        
        if let entryFace = entryFace, !canPass(from: entryFace, to: exitFace, through: position) {
          log.debug("Can't pass to exit face")
          continue
        }
        
        if !camera.isChunkSectionVisible(at: neighbourPosition) {
          log.debug("Frustum culled")
          continue
        }
        
        visited.insert(neighbourPosition)
        
        var directions = current.directions
        directions.insert(DirectionSet.member(exitFace))
        
        queue.append(SearchQueueEntry(
          position: neighbourPosition,
          entryFace: exitFace,
          directions: directions))
        
        visible.append(neighbourPosition)
      }
    }
    
    return visible
  }
}
