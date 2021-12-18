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
    return sections.count
  }
  
  // MARK: Private properties
  
  /// Used to make the graph threadsafe.
  private var lock = ReadWriteLock()
  /// Stores the connectivity for each chunk in the graph (see ``ChunkSectionFaceConnectivity``).
  private var sections: [ChunkSectionPosition: (connectivity: ChunkSectionFaceConnectivity, isEmpty: Bool)] = [:]
  /// All of the chunks currently in the visibility graph.
  private var chunks: Set<ChunkPosition> = []
  /// Block model palette used to determine whether blocks are see through or not.
  private let blockModelPalette: BlockModelPalette
  
  /// The x coordinate of the west-most chunk in the graph.
  private var minimumX = 0
  /// The x coordinate of the east-most chunk in the graph.
  private var maximumX = 0
  /// The z coordinate of the north-most chunk in the graph.
  private var minimumZ = 0
  /// The z coordinate of the south-most chunk in the graph.
  private var maximumZ = 0
  
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
    
    let isFirstChunk = chunks.isEmpty
    chunks.insert(position)
    
    // Update the bounding box of the visibility graph
    if isFirstChunk {
      minimumX = position.chunkX
      minimumZ = position.chunkZ
      maximumX = position.chunkX
      maximumZ = position.chunkZ
    } else {
      if position.chunkX < minimumX {
        minimumX = position.chunkX
      } else if position.chunkX > maximumX {
        maximumX = position.chunkX
      }
      
      if position.chunkZ < minimumZ {
        minimumZ = position.chunkZ
      } else if position.chunkZ > maximumZ {
        maximumZ = position.chunkZ
      }
    }
    
    // Calculate connectivity
    for (sectionY, section) in chunk.getSections().enumerated() {
      let sectionPosition = ChunkSectionPosition(position, sectionY: sectionY)
      var connectivityGraph = ChunkSectionVoxelGraph(for: section, blockModelPalette: blockModelPalette)
      sections[sectionPosition] = (connectivity: connectivityGraph.calculateConnectivity(), isEmpty: section.isEmpty)
    }
  }
  
  /// Removes the given chunk from the visibility graph.
  /// - Parameter position: The position of the chunk to remove.
  public mutating func removeChunk(at position: ChunkPosition) {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    chunks.remove(position)
    
    // Update the bounds of the graph if necessary
    if chunks.isEmpty {
      minimumX = 0
      minimumZ = 0
      maximumX = 0
      maximumZ = 0
    } else {
      if position.chunkX == minimumX {
        var minimum = Int.max
        for chunk in chunks {
          if chunk.chunkX < minimum {
            minimum = chunk.chunkX
          }
        }
        minimumX = minimum
      } else if position.chunkX == maximumX {
        var maximum = Int.min
        for chunk in chunks {
          if chunk.chunkX > maximum {
            maximum = chunk.chunkX
          }
        }
        maximumX = maximum
      }
      
      if position.chunkZ == minimumZ {
        var minimum = Int.max
        for chunk in chunks {
          if chunk.chunkZ < minimum {
            minimum = chunk.chunkZ
          }
        }
        minimumZ = minimum
      } else if position.chunkZ == maximumZ {
        var maximum = Int.min
        for chunk in chunks {
          if chunk.chunkZ > maximum {
            maximum = chunk.chunkZ
          }
        }
        maximumZ = maximum
      }
    }
    
    // Remove the chunk's sections from the graph.
    for y in 0..<Chunk.numSections {
      sections.removeValue(forKey: ChunkSectionPosition(position, sectionY: y))
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
  
  /// Recomputes the connectivity of the given section.
  /// - Parameters:
  ///   - position: The position of the section.
  ///   - chunk: The chunk that the section is in.
  public mutating func updateSection(at position: ChunkSectionPosition, in chunk: Chunk) {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    guard let section = chunk.getSection(at: position.sectionY) else {
      return
    }
    
    var connectivityGraph = ChunkSectionVoxelGraph(for: section, blockModelPalette: blockModelPalette)
    sections[position] = (connectivity: connectivityGraph.calculateConnectivity(), isEmpty: section.isEmpty)
  }
  
  /// Gets whether a ray could possibly pass through the given chunk section, entering through a given face and exiting out another given face.
  /// - Parameters:
  ///   - entryFace: Face to enter through.
  ///   - exitFace: Face to exit through.
  ///   - section: Section to check for.
  ///   - acquireLock: Whether to acquire a read lock or not. Only set to `false` if you know what you're doing.
  /// - Returns: Whether is it possibly to see through the section looking through `entryFace` and out `exitFace`.
  public func canPass(from entryFace: Direction, to exitFace: Direction, through section: ChunkSectionPosition, acquireLock: Bool = true) -> Bool {
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    let first = ChunkSectionFace.forDirection(entryFace)
    let second = ChunkSectionFace.forDirection(exitFace)
    if let connectivity = sections[section] {
      return connectivity.connectivity.areConnected(first, second)
    } else {
      return isWithinPaddedBounds(section)
    }
  }
  
  /// Gets whether the given section is within the bounds of the visibility graph, including 1 section of padding around the entire graph.
  /// - Parameter section: The position of the section.
  /// - Returns: `true` if the section is within the bounds of this graph.
  public func isWithinPaddedBounds(_ section: ChunkSectionPosition) -> Bool {
    return
      section.sectionX >= minimumX - 1 && section.sectionX <= maximumX + 1 &&
      section.sectionY >= -1 && section.sectionY <= Chunk.numSections + 1 &&
      section.sectionZ >= minimumZ - 1 && section.sectionZ <= maximumZ + 1
  }
  
  /// Gets the positions of all chunk sections that are possibly visible from the given chunk.
  /// - Parameter position: Position of the chunk section that the world is being viewed from.
  /// - Parameter camera: Used for frustum culling.
  /// - Returns: The positions of all possibly visible chunk sections. Does not include empty sections.
  public func chunkSectionsVisible(from camera: Camera) -> [ChunkSectionPosition] {
    lock.acquireReadLock()
    defer { lock.unlock() }
    
    // Move the position of the initial chunk to a more sensible position.
    var position = camera.entityPosition.chunkSection
    if position.sectionX < minimumX - 1 {
      position.sectionX = minimumX - 1
    } else if position.sectionX > maximumX + 1 {
      position.sectionX = maximumX + 1
    }
    
    if position.sectionY < -1 {
      position.sectionY = -1
    } else if position.sectionY > Chunk.numSections + 1 {
      position.sectionY = Chunk.numSections + 1
    }
    
    if position.sectionZ < minimumZ - 1 {
      position.sectionZ = minimumZ - 1
    } else if position.sectionZ > maximumZ + 1 {
      position.sectionZ = maximumZ + 1
    }
    
    // Traverse the graph to find all potentially visible sections
    var visible: [ChunkSectionPosition] = [position]
    visible.reserveCapacity(sectionCount)
    var visited = Set<ChunkSectionPosition>(minimumCapacity: sectionCount)
    var queue: Deque = [SearchQueueEntry(position: position, entryFace: nil, directions: [])]
    
    while let current = queue.popFirst() {
      let entryFace = current.entryFace
      let position = current.position
      
      for exitFace in Direction.allDirections where exitFace != entryFace {
        let neighbourPosition = position.neighbour(inDirection: exitFace)
        
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
          directions: directions
        ))
        
        if !(sections[neighbourPosition]?.isEmpty == true) {
          visible.append(neighbourPosition)
        }
      }
    }
    
    return visible
  }
}
