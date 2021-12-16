import Foundation

/// Represents a 16x256x16 (x y z) chunk of blocks in a world. Completely thread-safe.
///
/// Most of the public methods have an `acquireLock` parameter. To perform manual locking (for optimisation),
/// you can use ``acquireWriteLock()``, ``acquireReadLock()`` and ``unlock()``, along with `acquireLock: false`.
///
/// Sometimes referred to as a chunk column online. It is a column of ``Chunk/Section``s with
/// some extra information about block entities, biomes, lighting and heightmaps.
public final class Chunk {
  // MARK: Static properties
  
  /// The width of a chunk in the x direction.
  public static let width = 16
  /// The width of a chunk in the z direction.
  public static let depth = 16
  /// The height of a chunk in the y direction.
  public static let height = 256
  /// The number of blocks in each 1 block tall layer of a chunk.
  public static let blocksPerLayer = width * depth
  /// The total number of blocks per chunk.
  public static let numBlocks = height * blocksPerLayer
  /// The total number of sections per chunk.
  public static let numSections = 16
  
  // MARK: Public properties
  
  /// Whether the chunk has lighting data or not.
  public var hasLighting: Bool {
    lock.acquireReadLock()
    defer { lock.unlock() }
    
    return lighting.isPopulated
  }
  
  public var nonEmptySectionCount: Int {
    lock.acquireReadLock()
    defer { lock.unlock() }
    
    var count = 0
    for section in sections {
      if !section.isEmpty {
        count += 1
      }
    }
    return count
  }
  
  // MARK: Private properties
  
  /// Blocks are stored in chunk sections corresponding to 16x16x16 sections of the chunk from lowest to highest.
  private var sections: [Chunk.Section]
  /// Block entities for this chunk (i.e. chests, beds etc.)
  private var blockEntities: [BlockEntity]
  
  /// 3d biome data in 4x4x4 blocks.
  private var biomeIds: [UInt8]
  /// Lighting data that is populated once UpdateLightPacket is receive for this chunk.
  private var lighting = ChunkLighting()
  /// Information about the highest blocks in each column of the chunk.
  private var heightMap: HeightMap
  
  /// Lock for thread-safe reading and writing.
  private var lock = ReadWriteLock()
  
  // MARK: Init
  
  /// Creates a new chunk
  /// - Parameters:
  ///   - sections: An array of 16 chunk sections from lowest to highest.
  ///   - blockEntities: An array of block entities in the chunk in no particular order.
  ///   - biomeIds: The biomes of the chunk in 4x4x4 blocks. Indexed in the same order as blocks. (Index is block index divided by 4).
  ///   - lighting: Lighting data for the chunk
  ///   - heightMap: Information about the highest blocks in each column of the chunk.
  public init(sections: [Chunk.Section], blockEntities: [BlockEntity], biomeIds: [UInt8], lighting: ChunkLighting? = nil, heightMap: HeightMap) {
    self.sections = sections
    self.blockEntities = blockEntities
    self.biomeIds = biomeIds
    self.lighting = lighting ?? ChunkLighting()
    self.heightMap = heightMap
  }
  
  /// Creates a new chunk from the data contained within a chunk data packet.
  public init(_ packet: ChunkDataPacket) {
    self.heightMap = packet.heightMap
    self.blockEntities = packet.blockEntities
    self.sections = packet.sections
    self.biomeIds = packet.biomeIds
  }
  
  // MARK: Blocks
  
  /// Get information about a block.
  /// - Parameters:
  ///   - position: A block position relative to the chunk.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: Information about block and its state. Returns ``Block/missing`` if block state id is invalid.
  public func getBlock(at position: Position, acquireLock: Bool = true) -> Block {
    let stateId = getBlockId(at: position, acquireLock: acquireLock)
    return Registry.shared.blockRegistry.block(withId: stateId) ?? Block.missing
  }
  
  /// Get the block state id of the block at a position.
  /// - Parameters:
  ///   - position: A block position relative to the chunk.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: Block id of block. Returns 0 (regular air) if `position` is invalid (outside chunk).
  public func getBlockId(at position: Position, acquireLock: Bool = true) -> Int {
    let blockIndex = position.blockIndex
    return getBlockId(at: blockIndex, acquireLock: acquireLock)
  }
  
  /// Get the block state id of the block at an index.
  /// - Parameters:
  ///   - index: Can be obtained using ``Position/blockIndex``. Relative to the chunk.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: Block id of block. Returns 0 (air) if `index` is invalid (outside chunk).
  public func getBlockId(at index: Int, acquireLock: Bool = true) -> Int {
    if !Self.isValidBlockIndex(index) {
      log.warning("Invalid block index passed to Chunk.getBlockStateId(at:), index=\(index), returning block id 0 (air)")
      return 0
    }
    
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    let sectionIndex = index / Section.numBlocks
    let sectionBlockIndex = index % Section.numBlocks
    return sections[sectionIndex].getBlockId(at: sectionBlockIndex)
  }
  
  /// Sets the block at the given position to a new value.
  ///
  /// Updates the height map. **Does not update lighting**.
  ///
  /// - Parameters:
  ///   - position: A position relative to the chunk.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  ///   - newState: A new block state. Not validated.
  public func setBlockId(at position: Position, to state: Int, acquireLock: Bool = true) {
    if acquireLock { lock.acquireWriteLock() }
    defer { if acquireLock { lock.unlock() } }
    
    // TODO: Validate block state
    let blockIndex = position.blockIndex
    let sectionIndex = blockIndex / Section.numBlocks
    let sectionBlockIndex = blockIndex % Section.numBlocks
    sections[sectionIndex].setBlockId(at: sectionBlockIndex, to: state)
    
    heightMap.handleBlockUpdate(at: position, in: self, acquireChunkLock: false)
  }
  
  // MARK: Block entities
  
  /// Gets the chunk's block entities.
  /// - Parameter acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: The chunk's block entities.
  public func getBlockEntities(acquireLock: Bool = true) -> [BlockEntity] {
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    return blockEntities
  }
  
  /// Mutates the chunk's block entities with a closure.
  /// - Parameters:
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  ///   - action: Action that mutates the chunk's block entities.
  /// - Returns: The chunk's block entities.
  public func mutateBlockEntities(acquireLock: Bool = true, action: (inout [BlockEntity]) -> Void) {
    if acquireLock { lock.acquireWriteLock() }
    defer { if acquireLock { lock.unlock() } }
    
    action(&blockEntities)
  }
  
  // MARK: Biomes
  
  /// Gets the biome of the block at the given position.
  /// - Parameters:
  ///   - position: Position of block in chunk relative coordinates.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: Data about the biome.
  public func biomeId(at position: Position, acquireLock: Bool = true) -> Int {
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    let index = position.biomeIndex
    return Int(biomeIds[index])
  }
  
  /// Get the biome of the block at the given position.
  /// - Parameters:
  ///   - position: Position of block in chunk relative coordinates.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: Data about the biome.
  public func biome(at position: Position, acquireLock: Bool = true) -> Biome? {
    let biomeId = biomeId(at: position, acquireLock: acquireLock)
    return Registry.shared.biomeRegistry.biome(withId: biomeId)
  }
  
  /// Gets the chunk's biomes.
  /// - Parameter acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: The chunk's biomes.
  public func getBiomeIds(acquireLock: Bool = true) -> [UInt8] {
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    return biomeIds
  }
  
  /// Mutates the chunk's biomes with a closure.
  /// - Parameters:
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  ///   - action: Action that mutates the chunk's biomes.
  /// - Returns: The chunk's biomes.
  public func mutateBiomeIds(acquireLock: Bool = true, action: (inout [UInt8]) -> Void) {
    if acquireLock { lock.acquireWriteLock() }
    defer { if acquireLock { lock.unlock() } }
    
    action(&biomeIds)
  }
  
  // MARK: Sections
  
  /// Updates the chunk with data sent from the server.
  /// - Parameters:
  ///   - packet: Packet containing data to update this chunk with.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  public func update(with packet: ChunkDataPacket, acquireLock: Bool = true) {
    if acquireLock {
      lock.acquireWriteLock()
    }
    
    blockEntities = packet.blockEntities
    heightMap = packet.heightMap
    
    if acquireLock {
      lock.unlock()
    }
    
    for sectionIndex in packet.presentSections {
      setSection(atIndex: sectionIndex, to: packet.sections[sectionIndex], acquireLock: acquireLock)
    }
  }
  
  /// Replaces a section with a new one.
  /// - Parameters:
  ///   - index: A section index (from 0 to 15 inclusive). Not validated.
  ///   - section: The replacement section.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  public func setSection(atIndex index: Int, to section: Section, acquireLock: Bool = true) {
    if acquireLock { lock.acquireWriteLock() }
    defer { if acquireLock { lock.unlock() } }
    
    sections[index] = section
  }
  
  /// Gets the chunk's sections.
  /// - Parameter acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: The chunk's sections.
  public func getSections(acquireLock: Bool = true) -> [Section] {
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    let sections = sections
    return sections
  }
  
  /// Gets the section with the given y coordinate.
  /// - Parameters:
  ///   - y: The y coordinate of the section to get.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: The section. `nil` if the `y` coordinate is invalid.
  public func getSection(at y: Int, acquireLock: Bool = true) -> Section? {
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    guard y >= 0 && y < Self.numSections else {
      return nil
    }
    
    let section = sections[y]
    return section
  }
  
  /// Mutates the chunk's sections with a closure.
  /// - Parameters:
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  ///   - action: Action that mutates the chunk's sections.
  /// - Returns: The chunk's sections.
  public func mutateSections(acquireLock: Bool = true, action: (inout [Section]) -> Void) {
    if acquireLock { lock.acquireWriteLock() }
    defer { if acquireLock { lock.unlock() } }
    
    action(&sections)
  }
  
  // MARK: Lighting
  
  /// Returns the block light level for the given block.
  /// - Parameters:
  ///   - position: Position of block.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: The requested block light level.
  public func blockLightLevel(at position: Position, acquireLock: Bool = true) -> Int {
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    return lighting.getBlockLightLevel(at: position)
  }
  
  /// Sets the block light level for the given block. Does not propagate the change and does not verify the level is valid.
  /// - Parameters:
  ///   - position: Position of block.
  ///   - level: The new block light level.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  public func setBlockLightLevel(at position: Position, to level: Int, acquireLock: Bool = true) {
    if acquireLock { lock.acquireWriteLock() }
    defer { if acquireLock { lock.unlock() } }
    
    lighting.setBlockLightLevel(at: position, to: level)
  }
  
  /// Returns the sky light level for the given block.
  /// - Parameters:
  ///   - position: Position of block.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: The requested sky light level.
  public func skyLightLevel(at position: Position, acquireLock: Bool = true) -> Int {
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    return lighting.getSkyLightLevel(at: position)
  }
  
  /// Sets the sky light level for the given block. Does not propagate the change and does not verify the level is valid.
  /// - Parameters:
  ///   - position: Position of block.
  ///   - level: The new sky light level.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  public func setSkyLightLevel(at position: Position, to level: Int, acquireLock: Bool = true) {
    if acquireLock { lock.acquireWriteLock() }
    defer { if acquireLock { lock.unlock() } }
    
    lighting.setSkyLightLevel(at: position, to: level)
  }
  
  /// Updates the chunk's lighting with data received from the server.
  /// - Parameters:
  ///   - data: Data received from the server.
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  public func updateLighting(with data: ChunkLightingUpdateData, acquireLock: Bool = true) {
    if acquireLock { lock.acquireWriteLock() }
    defer { if acquireLock { lock.unlock() } }
    
    lighting.update(with: data)
  }
  
  /// Gets the chunk's lighting.
  /// - Parameter acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: The chunk's lighting.
  public func getLighting(acquireLock: Bool = true) -> ChunkLighting {
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    return lighting
  }
  
  /// Mutates the chunk's lighting with a closure.
  /// - Parameters:
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  ///   - action: Action that mutates the chunk's lighting.
  /// - Returns: The chunk's lighting.
  public func mutateLighting(acquireLock: Bool = true, action: (inout ChunkLighting) -> Void) {
    if acquireLock { lock.acquireWriteLock() }
    defer { if acquireLock { lock.unlock() } }
    
    action(&lighting)
  }
  
  // MARK: Height map
  
  /// Gets the height of the highest block that blocks light at the specified x and z coordinates.
  /// - Parameters:
  ///   - x: x coordinate of column.
  ///   - z: z coordinate of column.
  /// - Returns: Height of the highest block in the specified colum that blocks light. Returns 0 if `x` or `z` are out of bounds.
  public func highestLightBlockingBlock(atX x: Int, andZ z: Int, acquireLock: Bool = true) -> Int {
    guard x >= 0, x < Self.width, z >= 0, z < Self.depth else {
      return 0
    }
    
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    return heightMap.getHighestLightBlocking(x, z)
  }
  
  /// Gets the chunk's height map.
  /// - Parameter acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  /// - Returns: The chunk's height map.
  public func getHeightMap(acquireLock: Bool = true) -> HeightMap {
    if acquireLock { lock.acquireReadLock() }
    defer { if acquireLock { lock.unlock() } }
    
    return heightMap
  }
  
  /// Mutates the chunk's height map with a closure.
  /// - Parameters:
  ///   - acquireLock: Whether to acquire a lock or not. Only set to false if you know what you're doing. See ``Chunk``.
  ///   - action: Action that mutates the chunk's height map.
  /// - Returns: The chunk's height map.
  public func mutateHeightMap(acquireLock: Bool = true, action: (inout HeightMap) -> Void) {
    if acquireLock { lock.acquireWriteLock() }
    defer { if acquireLock { lock.unlock() } }
    
    action(&heightMap)
  }
  
  // MARK: Locking
  
  /// Acquire a lock for manually writing data to the chunk (e.g. writing to the sections directly).
  ///
  /// Do not call any of the public methods of this chunk until you call ``unlock()`` because that
  /// might create a deadlock (unless you pass `acquireLock: false` to the method).
  public func acquireWriteLock() {
    lock.acquireWriteLock()
  }
  
  /// Acquire a lock for manually reading data from the chunk (e.g. accessing the sections directly).
  ///
  /// Do not call any of the public methods of this chunk until you call ``unlock()`` because that
  /// might create a deadlock.
  public func acquireReadLock() {
    lock.acquireReadLock()
  }
  
  /// Release the lock after calling ``acquireReadLock()`` or ``acquireWriteLock()``.
  public func unlock() {
    lock.unlock()
  }
  
  // MARK: Static methods
  
  /// - Returns: `true` if the block index is contained within a chunk.
  private static func isValidBlockIndex(_ index: Int) -> Bool {
    return index >= 0 && index < Chunk.numBlocks
  }
  
  /// - Returns: `true` if the block position is contained within the a chunk.
  private static func isValidBlockPosition(_ position: Position) -> Bool {
    return (
      position.x < Chunk.width && position.x >= 0 &&
      position.z < Chunk.depth && position.z >= 0 &&
      position.y < Chunk.height && position.y >= 0)
  }
}
