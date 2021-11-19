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
  
  // MARK: Init
  
  /// Creates a new world mesh. Prepares any chunks already loaded in the world.
  public init(_ world: World, resources: ResourcePack.Resources) {
    self.world = world
    meshWorker = WorldMeshWorker(world: world, resources: resources)
    
    for (position, chunk) in world.chunks {
      addChunk(chunk, at: position)
    }
  }
  
  // MARK: Public methods
  
  public mutating func getMeshes() -> [ChunkSectionMesh] {
    meshesLock.acquireWriteLock()
    let updatedMeshes = meshWorker.getUpdatedMeshes()
    for (position, mesh) in updatedMeshes {
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
    let meshes = meshes
    meshesLock.unlock()
    return meshes
  }
  
  public mutating func handleChunkAdded(at position: ChunkPosition) {
    let positions = position.andNeighbours
    for position in positions {
      if !chunks.contains(position), world.chunkComplete(at: position), let chunk = world.chunk(at: position) {
        addChunk(chunk, at: position)
        meshesLock.acquireWriteLock()
        chunks.insert(position)
        meshesLock.unlock()
      }
    }
  }
  
  public mutating func addChunk(_ chunk: Chunk, at position: ChunkPosition) {
    guard let neighbours = world.allNeighbours(ofChunkAt: position) else {
      return
    }
    
    // TODO: lock chunks while their meshes are being prepared
    for (sectionY, section) in chunk.getSections(acquireLock: false).enumerated() where section.blockCount != 0 {
      meshWorker.createMeshAsync(
        at: ChunkSectionPosition(position, sectionY: sectionY),
        in: chunk,
        neighbours: neighbours,
        priority: .chunkLoad)
    }
  }
}
