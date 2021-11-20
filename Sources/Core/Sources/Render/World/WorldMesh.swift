/// Holds all the meshes for a world.
public struct WorldMesh {
  // MARK: Private properties
  
  /// The world this mesh is for.
  private var world: World
  /// A worker that handles the preparation and updating of meshes.
  private var meshWorker: WorldMeshWorker
  
  /// All chunk section meshes.
  private var meshes: [ChunkSectionMesh] = []
  /// A lock for reading and writing `meshes`, `meshPositionToIndex`, `chunkToMeshIndices` and `chunks`.
  private var meshesLock = ReadWriteLock()
  /// Maps chunk section position to an index in `meshes`.
  private var meshPositionToIndex: [ChunkSectionPosition: Int] = [:]
  /// Maps chunk position to indices of all of that chunk's meshes.
  private var chunkToMeshIndices: [ChunkPosition: [Int]] = [:]
  /// Positions of all chunks that currently have meshes prepared.
  private var chunks: Set<ChunkPosition> = []
  /// How many times each chunk is currently locked.
  private var chunkLockCounts: [ChunkPosition: Int] = [:]
  
  // MARK: Init
  
  /// Creates a new world mesh. Prepares any chunks already loaded in the world.
  public init(_ world: World, resources: ResourcePack.Resources) {
    self.world = world
    meshWorker = WorldMeshWorker(world: world, resources: resources)
    
    for (position, _) in world.chunks {
      handleChunkAdded(at: position)
    }
  }
  
  // MARK: Public methods
  
  public mutating func mutateMeshes(_ action: (inout [ChunkSectionMesh]) throws -> Void) rethrows {
    meshesLock.acquireWriteLock()
    defer { meshesLock.unlock() }
    
    let updatedMeshes = meshWorker.getUpdatedMeshes()
    for (position, mesh) in updatedMeshes {
      for position in chunksRequiredToPrepare(chunkAt: position.chunk) {
        unlockChunk(at: position)
      }
      
      if let index = meshPositionToIndex[position] {
        meshes[index] = mesh
      } else {
        let index = meshes.count
        meshes.append(mesh)
        meshPositionToIndex[position] = index
        var chunkIndices = chunkToMeshIndices[position.chunk] ?? []
        chunkIndices.append(index)
        chunkToMeshIndices[position.chunk] = chunkIndices
      }
    }
    
    try action(&meshes)
  }
  
  public mutating func handleChunkAdded(at position: ChunkPosition) {
    guard world.chunkComplete(at: position) else {
      return
    }
    
    // The chunks required to prepare this chunk is the same as the chunks that require this chunk to prepare.
    // Adding this chunk may have made some of the chunks that require it preparable so here we check if any of
    // those can now by prepared. `chunksRequiredToPrepare` includes the chunk itself as well.
    for position in chunksRequiredToPrepare(chunkAt: position) {
      // TODO: check if all neighbours are also complete
      // TODO: lock in a 3x3 ring around the chunk being prepared
      if !hasPreparedChunk(at: position) && canPrepareChunk(at: position) {
        prepareChunk(at: position)
      }
    }
  }
  
  public mutating func prepareChunk(at position: ChunkPosition) {
    guard let chunk = world.chunk(at: position), let neighbours = world.allNeighbours(ofChunkAt: position) else {
      log.warning("Failed to get chunk and neighbours to prepare mesh. They seem to have disappeared.")
      return
    }
    
    meshesLock.acquireWriteLock()
    chunks.insert(position)
    meshesLock.unlock()
    
    for position in chunksRequiredToPrepare(chunkAt: position) {
      lockChunk(at: position)
    }
    
    var sections: [ChunkSectionPosition: (Chunk, ChunkNeighbours)] = [:]
    
    for (sectionY, section) in chunk.getSections(acquireLock: false).enumerated() where section.blockCount != 0 {
      sections[ChunkSectionPosition(position, sectionY: sectionY)] = (chunk, neighbours)
    }
    
    meshWorker.createMeshesAsync(sections, priority: .chunkLoad)
  }
  
  // MARK: Private helper methods
  
  private func hasPreparedChunk(at position: ChunkPosition) -> Bool {
    meshesLock.acquireReadLock()
    defer { meshesLock.unlock() }
    return chunks.contains(position)
  }
  
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
  
  private mutating func lockChunk(at position: ChunkPosition) {
    if let chunk = world.chunk(at: position) {
      chunk.acquireReadLock()
      meshesLock.acquireWriteLock()
      chunkLockCounts[position] = (chunkLockCounts[position] ?? 0) + 1
      meshesLock.unlock()
    } else {
      log.warning("WorldMesh attempted to lock non-existent chunk at \(position).")
    }
  }
  
  private mutating func unlockChunk(at position: ChunkPosition) {
    meshesLock.acquireWriteLock()
    defer { meshesLock.unlock() }
    
    if let lockCount = chunkLockCounts[position] {
      if lockCount == 0 {
        chunkLockCounts.removeValue(forKey: position)
      } else if lockCount == 1 {
        world.chunk(at: position)?.unlock()
        chunkLockCounts.removeValue(forKey: position)
      } else {
        world.chunk(at: position)?.unlock()
        chunkLockCounts[position] = lockCount - 1
      }
    } else {
      log.warning("Chunk at \(position) double unlocked")
    }
  }
}
