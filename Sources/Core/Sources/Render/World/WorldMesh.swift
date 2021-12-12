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
  /// Positions of all chunks that currently have meshes prepared.
  private var chunks: Set<ChunkPosition> = []
  /// How many times each chunk is currently locked.
  private var chunkLockCounts: [ChunkPosition: Int] = [:]
  
  // MARK: Init
  
  /// Creates a new world mesh. Prepares any chunks already loaded in the world.
  public init(_ world: World, cameraChunk: ChunkPosition, resources: ResourcePack.Resources) {
    self.world = world
    meshWorker = WorldMeshWorker(world: world, resources: resources)
    visibilityGraph = VisibilityGraph(blockModelPalette: resources.blockModelPalette)
    
    let chunks = world.loadedChunkPositions
    
    var stopwatch = Stopwatch(mode: .verbose, name: "Visibility graph creation")
    for position in chunks {
      stopwatch.startMeasurement("Process chunk")
      addChunk(at: position)
      stopwatch.stopMeasurement("Process chunk")
    }
  }
  
  // MARK: Public methods
  
  /// Updates the world mesh (should ideally be called once per frame).
  /// - Parameters:
  ///   - cameraPosition: The current position of the camera.
  ///   - camera: The camera the world is being viewed from.
  public mutating func update(_ cameraPosition: ChunkSectionPosition, camera: Camera) {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    let visibleSections = visibilityGraph.chunkSectionsVisible(from: cameraPosition, camera: camera)
    log.debug("Visible section count: \(visibleSections.count)")
    log.debug("Visibility graph size: \(visibilityGraph.sectionCount)")
    
    for section in visibleSections {
      if !hasPreparedChunk(at: section.chunk) {
        log.debug("Still preparing sections")
        for position in chunksRequiredToPrepare(chunkAt: section.chunk) {
          lockChunk(at: position)
        }
        
        lockChunk(at: section.chunk)
        prepareChunkSection(at: section, acquireLocks: false)
      }
    }
  }
  
  /// Perform an arbitrary action that mutates the world's meshes.
  /// - Parameter action: Action to perform on the meshes.
  public mutating func mutateMeshes(_ action: (inout [ChunkSectionPosition: ChunkSectionMesh]) throws -> Void) rethrows {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    let updatedMeshes = meshWorker.getUpdatedMeshes()
    for (position, mesh) in updatedMeshes {
      for position in chunksRequiredToPrepare(chunkAt: position.chunk) {
        unlockChunk(at: position)
      }
      
      meshes[position] = mesh
    }
    
    try action(&meshes)
  }
  
  /// Adds a chunk to the mesh.
  /// - Parameter position: Position of the newly added chunk.
  public mutating func addChunk(at position: ChunkPosition) {
    // `VisibilityGraph` is threadsafe so only a read lock is required.
    lock.acquireReadLock()
    defer { lock.unlock() }
    
    guard world.chunkComplete(at: position) else {
      return
    }
    
    // The chunks required to prepare this chunk is the same as the chunks that require this chunk to prepare.
    // Adding this chunk may have made some of the chunks that require it preparable so here we check if any of
    // those can now by prepared. `chunksRequiredToPrepare` includes the chunk itself as well.
    for position in chunksRequiredToPrepare(chunkAt: position) {
      if !hasPreparedChunk(at: position) && canPrepareChunk(at: position) {
        if let chunk = world.chunk(at: position) {
          visibilityGraph.addChunk(chunk, at: position)
        }
      }
    }
  }
  
  /// Prepares the mesh for a chunk.
  /// - Parameter position: The position of the chunk to prepare.
  public mutating func prepareChunk(at position: ChunkPosition) {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    guard let chunk = world.chunk(at: position), let neighbours = world.allNeighbours(ofChunkAt: position) else {
      log.warning("Failed to get chunk and neighbours to prepare mesh. They seem to have disappeared.")
      return
    }
    
    chunks.insert(position)
    visibilityGraph.updateChunk(chunk, at: position)
    
    let nonEmptySectionCount = chunk.getSections().filter({ !$0.isEmpty }).count
    for position in chunksRequiredToPrepare(chunkAt: position) {
      lockChunk(at: position, numberOfTimes: nonEmptySectionCount)
    }
    
    for (sectionY, section) in chunk.getSections(acquireLock: false).enumerated() {
      let sectionPosition = ChunkSectionPosition(position, sectionY: sectionY)
      if section.blockCount != 0 {
        meshWorker.createMeshAsync(
          at: sectionPosition,
          in: chunk,
          neighbours: neighbours)
      } else {
        meshes[sectionPosition] = nil
      }
    }
  }
  
  /// Prepares the mesh for a chunk section.
  /// - Parameter position: The position of the section to prepare.
  public mutating func prepareChunkSection(at position: ChunkSectionPosition) {
    prepareChunkSection(at: position, acquireLocks: true)
  }
  
  /// Prepares the mesh for a chunk section. Threadsafe.
  /// - Parameters:
  ///   - position: The position of the section to prepare.
  ///   - acquireLocks: If false, the chunk and its neighbours must be locked manually (with `lockChunk(at:)`) and so must `lock`.
  private mutating func prepareChunkSection(at position: ChunkSectionPosition, acquireLocks: Bool) {
    let chunkPosition = position.chunk
    
    guard let chunk = world.chunk(at: chunkPosition), let neighbours = world.allNeighbours(ofChunkAt: chunkPosition) else {
      log.warning("Failed to get chunk and neighbours to prepare mesh. They seem to have disappeared.")
      return
    }
    
    visibilityGraph.updateChunk(chunk, at: position.chunk)
    
    if acquireLocks {
      lock.acquireWriteLock()
    }
    
    chunks.insert(chunkPosition)
    
    if acquireLocks {
      lock.unlock()
      lockChunk(at: chunkPosition)
    }
    
    meshWorker.createMeshAsync(
      at: position,
      in: chunk,
      neighbours: neighbours)
  }
  
  // MARK: Private helper methods
  
  /// Checks whether a chunk has been prepared (or started to be prepared).
  ///
  /// Does not perform any locking (isn't threadsafe).
  /// - Parameter position: The position of the chunk to check.
  /// - Returns: Whether the chunk has been prepared or not.
  private func hasPreparedChunk(at position: ChunkPosition) -> Bool {
    return chunks.contains(position)
  }
  
  /// Checks whether a chunk has all the neighbours required to prepare it (including lighting).
  ///
  /// Does not perform any locking (isn't threadsafe).
  /// - Parameter position: The position of the chunk to check.
  /// - Returns: Whether the chunk can be prepared or not.
  private func canPrepareChunk(at position: ChunkPosition) -> Bool {
    // TODO: Cache which chunks are complete
    
    for position in chunksRequiredToPrepare(chunkAt: position) {
      if !world.chunkComplete(at: position) {
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
