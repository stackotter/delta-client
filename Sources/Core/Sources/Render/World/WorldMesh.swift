import simd

/// Holds all the meshes for a world. Completely threadsafe.
public struct WorldMesh {
  // MARK: Private properties
  
  /// The world this mesh is for.
  private var world: World
  /// Used to determine which chunk sections should be rendered.
  private var visibilityGraph: VisibilityGraph
  
  /// A lock used to make the mesh threadsafe.
  private var lock = ReadWriteLock()
  
  /// A worker that handles the preparation and updating of meshes.
  private var meshWorker: WorldMeshWorker
  /// All chunk section meshes.
  private var meshes: [ChunkSectionPosition: ChunkSectionMesh] = [:]
  /// Positions of all chunk sections that need to have their meshes prepared again when they next become visible.
  private var chunkSectionsToPrepare: Set<ChunkSectionPosition> = []
  /// How many times each chunk is currently locked.
  private var chunkLockCounts: [ChunkPosition: Int] = [:]
  /// Positions of all currently visible chunk sections (updated when ``update(_:camera:)`` is called.
  private var visibleSections: [ChunkSectionPosition] = []
  
  // MARK: Init
  
  /// Creates a new world mesh. Prepares any chunks already loaded in the world.
  public init(_ world: World, cameraChunk: ChunkPosition, resources: ResourcePack.Resources) {
    self.world = world
    meshWorker = WorldMeshWorker(world: world, resources: resources)
    visibilityGraph = VisibilityGraph(blockModelPalette: resources.blockModelPalette)
    
    let chunks = world.loadedChunkPositions
    
    var stopwatch = Stopwatch(mode: .summary, name: "Visibility graph creation")
    for position in chunks {
      stopwatch.startMeasurement("Process chunk")
      addChunk(at: position)
      stopwatch.stopMeasurement("Process chunk")
    }
    stopwatch.summary()
  }
  
  // MARK: Public methods
  
  /// Adds a chunk to the mesh.
  /// - Parameter position: Position of the newly added chunk.
  public mutating func addChunk(at position: ChunkPosition) {
    // `VisibilityGraph` is threadsafe so only a read lock is required.
    lock.acquireReadLock()
    defer { lock.unlock() }
    
    guard world.isChunkComplete(at: position) else {
      return
    }
    
    // The chunks required to prepare this chunk is the same as the chunks that require this chunk to prepare.
    // Adding this chunk may have made some of the chunks that require it preparable so here we check if any of
    // those can now by prepared. `chunksRequiredToPrepare` includes the chunk itself as well.
    for position in chunksRequiredToPrepare(chunkAt: position) {
      if canPrepareChunk(at: position) && !visibilityGraph.containsChunk(at: position) {
        if let chunk = world.chunk(at: position) {
          visibilityGraph.addChunk(chunk, at: position)
          
          // Mark any non-empty sections of the chunk for preparation. It doesn't actually mutate, that's just the API I had to use.
          chunk.mutateSections(action: { sections in
            for (y, section) in sections.enumerated() where !section.isEmpty {
              let sectionPosition = ChunkSectionPosition(position, sectionY: y)
              chunkSectionsToPrepare.insert(sectionPosition)
            }
          })
        }
      }
    }
  }
  
  /// Updates the world mesh (should ideally be called once per frame).
  /// - Parameters:
  ///   - cameraPosition: The current position of the camera.
  ///   - camera: The camera the world is being viewed from.
  public mutating func update(_ cameraPosition: ChunkSectionPosition, camera: Camera) {
    var stopwatch = Stopwatch(mode: .verbose, name: "WorldMesh.update")
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    visibleSections = visibilityGraph.chunkSectionsVisible(from: cameraPosition, camera: camera)
    
    stopwatch.startMeasurement("Prepare sections")
    for section in visibleSections {
      if section == ChunkSectionPosition(sectionX: -12, sectionY: 6, sectionZ: -24) {
        log.debug("Section at (-12, 6, -24) is visible")
      }
      if shouldPrepareChunkSection(at: section) {
        if section == ChunkSectionPosition(sectionX: -12, sectionY: 6, sectionZ: -24) {
          log.debug("Section at (-12, 6, -24) is getting prepared")
        }
        prepareChunkSection(at: section, acquireWriteLock: false)
      }
    }
    stopwatch.stopMeasurement("Prepare sections")
  }
  
  /// Perform an arbitrary action that mutates each of the world's visible meshes.
  /// - Parameter action: Action to perform on each visible mesh.
  /// - Parameter shouldReverseOrder: If `true`, the sections will be mutated from furthest to closest.
  public mutating func mutateVisibleMeshes(fromBackToFront shouldReverseOrder: Bool = false, _ action: (ChunkSectionPosition, inout ChunkSectionMesh) throws -> Void) rethrows {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    let updatedMeshes = meshWorker.getUpdatedMeshes()
    for (position, mesh) in updatedMeshes {
      for position in chunksRequiredToPrepare(chunkAt: position.chunk) {
        unlockChunk(at: position)
      }
      
      meshes[position] = mesh
    }
    
    let sections = shouldReverseOrder ? visibleSections.reversed() : visibleSections
    for position in sections {
      if meshes[position] != nil {
        try action(position, &meshes[position]!)
      }
    }
  }
  
  // MARK: Private methods
  
  /// Prepares the mesh for a chunk section. Threadsafe.
  /// - Parameters:
  ///   - position: The position of the section to prepare.
  ///   - acquireWriteLock: If false, a write lock for `lock` must be acquired prior to calling this method.
  private mutating func prepareChunkSection(at position: ChunkSectionPosition, acquireWriteLock: Bool) {
    chunkSectionsToPrepare.remove(position)
    
    let chunkPosition = position.chunk
    
    if acquireWriteLock {
      lock.acquireWriteLock()
    }
    
    // TODO: This should possibly throw an error instead of failing silently
    guard let chunk = world.chunk(at: chunkPosition), let neighbours = world.allNeighbours(ofChunkAt: chunkPosition) else {
      log.warning("Failed to get chunk and neighbours of section at \(position)")
      visibilityGraph.removeChunk(at: chunkPosition)
      return
    }
    
    if acquireWriteLock {
      lock.unlock()
    }
    
    for position in chunksRequiredToPrepare(chunkAt: chunkPosition) {
      lockChunk(at: position)
    }
    
    meshWorker.createMeshAsync(
      at: position,
      in: chunk,
      neighbours: neighbours)
  }
  
  /// Checks whether a chunk section should be prepared when it next becomes visible.
  ///
  /// Does not perform any locking (isn't threadsafe).
  /// - Parameter position: The position of the chunk section to check.
  /// - Returns: Whether the chunk section should be prepared or not.
  private func shouldPrepareChunkSection(at position: ChunkSectionPosition) -> Bool {
    return chunkSectionsToPrepare.contains(position)
  }
  
  /// Checks whether a chunk has all the neighbours required to prepare it (including lighting).
  ///
  /// Does not perform any locking (isn't threadsafe).
  /// - Parameter position: The position of the chunk to check.
  /// - Returns: Whether the chunk can be prepared or not.
  private func canPrepareChunk(at position: ChunkPosition) -> Bool {
    for position in chunksRequiredToPrepare(chunkAt: position) {
      if !world.isChunkComplete(at: position) {
        return false
      }
    }
    
    return true
  }
  
  /// Gets the list of chunks that must be present to prepare a chunk, including the chunk itself.
  /// - Parameter position: Chunk to get dependencies of.
  /// - Returns: Chunks that must be present to prepare the given chunk, including the chunk itself.
  private func chunksRequiredToPrepare(chunkAt position: ChunkPosition) -> [ChunkPosition] {
    return [
      position,
      position.neighbour(inDirection: .north),
      position.neighbour(inDirection: .north).neighbour(inDirection: .east),
      position.neighbour(inDirection: .east),
      position.neighbour(inDirection: .south).neighbour(inDirection: .east),
      position.neighbour(inDirection: .south),
      position.neighbour(inDirection: .south).neighbour(inDirection: .west),
      position.neighbour(inDirection: .west),
      position.neighbour(inDirection: .north).neighbour(inDirection: .west)]
  }
  
  /// Acquires a read lock for the given chunk if the world mesh doesn't already have one.
  ///
  /// Is not threadsafe. `lock` must be acquired manually.
  ///
  /// Updates the count of how many times `unlockChunk` should be called before it as actually unlocked.
  /// There should be one unlock for every lock and when they even out the lock is released.
  /// - Parameters:
  ///   - position: Position of chunk to lock.
  ///   - count: Number of unlocks to expect for this lock call.
  private mutating func lockChunk(at position: ChunkPosition, numberOfTimes count: Int = 1) {
    if let chunk = world.chunk(at: position) {
      if let lockCount = chunkLockCounts[position] {
        chunkLockCounts[position] = lockCount + count
      } else {
        chunk.acquireReadLock()
        chunkLockCounts[position] = count
      }
    } else {
      log.warning("WorldMesh attempted to lock non-existent chunk at \(position).")
    }
  }
  
  /// Unlocks the chunk if there have been the same number of locks as unlocks.
  ///
  /// Is not threadsafe. `lock` must be acquired manually.
  /// - Parameter position: Chunk to unlock.
  private mutating func unlockChunk(at position: ChunkPosition) {
    guard let lockCount = chunkLockCounts[position] else {
      log.warning("Chunk at \(position) double unlocked")
      return
    }
  
    if lockCount == 0 {
      chunkLockCounts.removeValue(forKey: position)
    } else if lockCount == 1 {
      guard let chunk = world.chunk(at: position) else {
        log.warning("WorldMesh attempted to unlock non-existent chunk at \(position).")
        return
      }
      
      chunk.unlock()
      chunkLockCounts.removeValue(forKey: position)
    } else {
      chunkLockCounts[position] = lockCount - 1
    }
  }
}
