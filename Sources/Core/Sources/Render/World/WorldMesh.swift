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
  /// Positions of all currently visible chunk sections (updated when ``update(_:camera:)`` is called.
  private var visibleSections: [ChunkSectionPosition] = []
  
  // MARK: Init
  
  /// Creates a new world mesh. Prepares any chunks already loaded in the world.
  public init(_ world: World, cameraChunk: ChunkPosition, resources: ResourcePack.Resources) {
    self.world = world
    meshWorker = WorldMeshWorker(world: world, resources: resources)
    visibilityGraph = VisibilityGraph(blockModelPalette: resources.blockModelPalette)
    
    let chunks = world.loadedChunkPositions
    
    for position in chunks {
      addChunk(at: position)
    }
  }
  
  // MARK: Public methods
  
  /// Adds a chunk to the mesh.
  /// - Parameter position: Position of the newly added chunk.
  public mutating func addChunk(at position: ChunkPosition) {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    guard world.isChunkComplete(at: position) else {
      return
    }
    
    // The chunks required to prepare this chunk is the same as the chunks that require this chunk to prepare.
    // Adding this chunk may have made some of the chunks that require it preparable so here we check if any of
    // those can now by prepared. `chunksRequiredToPrepare` includes the chunk itself as well.
    for position in Self.chunksRequiredToPrepare(chunkAt: position) {
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
  
  /// Removes the given chunk from the mesh.
  ///
  /// This method has an issue where any chunk already queued to be prepared will still be prepared and stored.
  /// However, it will not be rendered, so this isn't much of an issue. And it probably won't happen often anyway.
  /// - Parameter position: The position of the chunk to remove.
  public mutating func removeChunk(at position: ChunkPosition) {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    for position in Self.chunksRequiredToPrepare(chunkAt: position) {
      visibilityGraph.removeChunk(at: position)
      
      for y in 0..<Chunk.numSections {
        let sectionPosition = ChunkSectionPosition(position, sectionY: y)
        chunkSectionsToPrepare.remove(sectionPosition)
        meshes.removeValue(forKey: sectionPosition)
      }
    }
  }
  
  /// Schedules a chunk to have its meshes updated next time it is visible.
  /// - Parameter position: The position of the chunk to update.
  public mutating func updateChunk(at position: ChunkPosition) {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    guard let chunk = world.chunk(at: position) else {
      log.warning("Chunk update received for non-existent chunk \(position)")
      return
    }
    
    visibilityGraph.updateChunk(chunk, at: position)
    
    for (y, section) in chunk.getSections().enumerated() {
      if !section.isEmpty {
        let position = ChunkSectionPosition(position, sectionY: y)
        chunkSectionsToPrepare.insert(position)
      }
    }
  }
  
  /// Schedules a chunk section to have its mesh updated next time it is visible.
  /// - Parameter position: The position of the chunk section to update.
  public mutating func updateSection(at position: ChunkSectionPosition) {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    guard let chunk = world.chunk(at: position.chunk) else {
      log.warning("Chunk section update received for non-existent chunk section \(position)")
      return
    }
    
    visibilityGraph.updateSection(at: position, in: chunk)
    chunkSectionsToPrepare.insert(position)
  }
  
  /// Updates the world mesh (should ideally be called once per frame).
  /// - Parameters:
  ///   - cameraPosition: The current position of the camera.
  ///   - camera: The camera the world is being viewed from.
  public mutating func update(_ cameraPosition: ChunkSectionPosition, camera: Camera) {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    visibleSections = visibilityGraph.chunkSectionsVisible(from: cameraPosition, camera: camera)
    
    for section in visibleSections {
      if shouldPrepareChunkSection(at: section) {
        prepareChunkSection(at: section, acquireWriteLock: false)
      }
    }
  }
  
  /// Perform an arbitrary action that mutates each of the world's visible meshes.
  /// - Parameter action: Action to perform on each visible mesh.
  /// - Parameter shouldReverseOrder: If `true`, the sections will be mutated from furthest to closest.
  public mutating func mutateVisibleMeshes(fromBackToFront shouldReverseOrder: Bool = false, _ action: (ChunkSectionPosition, inout ChunkSectionMesh) throws -> Void) rethrows {
    lock.acquireWriteLock()
    defer { lock.unlock() }
    
    let updatedMeshes = meshWorker.getUpdatedMeshes()
    for (position, mesh) in updatedMeshes {
      meshes[position] = mesh
    }
    
    let sections = shouldReverseOrder ? visibleSections.reversed() : visibleSections
    for position in sections {
      if meshes[position] != nil {
        try action(position, &meshes[position]!)
      }
    }
  }
  
  /// Gets an array containing the position of each section affected by the update (including the section itself).
  ///
  /// This function shouldn't need to be `mutating`, but it causes crashes if it is not.
  /// - Parameter position: The position of the chunk section.
  /// - Parameter onlyLighting: If true, the update will be treated as if only lighting has changed.
  /// - Returns: The affected chunk sections.
  public mutating func sectionsAffectedBySectionUpdate(at position: ChunkSectionPosition, onlyLighting: Bool = false) -> [ChunkSectionPosition] {
    lock.acquireReadLock()
    defer { lock.unlock() }
    
    var sections = [
      position,
      position.neighbour(inDirection: .north),
      position.neighbour(inDirection: .south),
      position.neighbour(inDirection: .east),
      position.neighbour(inDirection: .west),
      position.neighbour(inDirection: .up),
      position.neighbour(inDirection: .down)
    ].compactMap { $0 }
    
    if onlyLighting {
      return sections
    }
    
    // The following sections are only affected if they contain fluids
    let potentiallyAffected = [
      position.neighbour(inDirection: .north)?.neighbour(inDirection: .east),
      position.neighbour(inDirection: .north)?.neighbour(inDirection: .east)?.neighbour(inDirection: .down),
      position.neighbour(inDirection: .north)?.neighbour(inDirection: .west),
      position.neighbour(inDirection: .north)?.neighbour(inDirection: .west)?.neighbour(inDirection: .down),
      position.neighbour(inDirection: .south)?.neighbour(inDirection: .west),
      position.neighbour(inDirection: .south)?.neighbour(inDirection: .west)?.neighbour(inDirection: .down),
      position.neighbour(inDirection: .south)?.neighbour(inDirection: .west),
      position.neighbour(inDirection: .south)?.neighbour(inDirection: .west)?.neighbour(inDirection: .down),
      position.neighbour(inDirection: .north)?.neighbour(inDirection: .down),
      position.neighbour(inDirection: .east)?.neighbour(inDirection: .down),
      position.neighbour(inDirection: .south)?.neighbour(inDirection: .down),
      position.neighbour(inDirection: .west)?.neighbour(inDirection: .down)
    ].compactMap { $0 }
    
    for section in potentiallyAffected {
      if let mesh = meshes[section] {
        if mesh.containsFluids {
          sections.append(section)
        }
      }
    }
    
    return sections
  }
  
  /// Gets the list of chunks that must be present to prepare a chunk, including the chunk itself.
  /// - Parameter position: Chunk to get dependencies of.
  /// - Returns: Chunks that must be present to prepare the given chunk, including the chunk itself.
  public static func chunksRequiredToPrepare(chunkAt position: ChunkPosition) -> [ChunkPosition] {
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
  
  // MARK: Private methods
  
  /// Prepares the mesh for a chunk section. Threadsafe.
  /// - Parameters:
  ///   - position: The position of the section to prepare.
  ///   - acquireWriteLock: If false, a write lock for `lock` must be acquired prior to calling this method.
  private mutating func prepareChunkSection(at position: ChunkSectionPosition, acquireWriteLock: Bool) {
    if acquireWriteLock { lock.acquireWriteLock() }
    defer { if acquireWriteLock { lock.unlock() } }
    
    let chunkPosition = position.chunk
    chunkSectionsToPrepare.remove(position)
    
    // TODO: This should possibly throw an error instead of failing silently
    guard let chunk = world.chunk(at: chunkPosition), let neighbours = world.allNeighbours(ofChunkAt: chunkPosition) else {
      log.warning("Failed to get chunk and neighbours of section at \(position)")
      visibilityGraph.removeChunk(at: chunkPosition)
      return
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
    for position in Self.chunksRequiredToPrepare(chunkAt: position) {
      if !world.isChunkComplete(at: position) {
        return false
      }
    }
    
    return true
  }
}
