import Foundation
import simd
import Logging

/// Represents a Minecraft world. Completely thread-safe.
///
/// Includes chunks, lighting and some other metadata.
public class World {
  // MARK: Public properties

  /// The bus the world will emit events to.
  public var eventBus: EventBus {
    get {
      eventBusLock.acquireReadLock()
      defer { eventBusLock.unlock() }
      return _eventBus
    }
    set {
      eventBusLock.acquireWriteLock()
      defer { eventBusLock.unlock() }
      _eventBus = newValue
    }
  }

  /// The positions of all loaded chunks.
  public var loadedChunkPositions: [ChunkPosition] {
    terrainLock.acquireReadLock()
    defer { terrainLock.unlock() }
    return [ChunkPosition](chunks.keys)
  }

  // MARK: Public metadata properties

  /// The name of this world
  public let name: Identifier
  /// The dimension data for this world
  public let dimension: Identifier
  /// The hashed seed of this world
  public let hashedSeed: Int
  /// Whether this world is a debug world or not
  public let isDebug: Bool
  /// Whether this world is superflat or not.
  public let isFlat: Bool

  // MARK: Private properties

  /// Lock for managing thread-safe read and write of ``age`` and ``timeOfDay``.
  private var timeLock = ReadWriteLock()
  /// The world's age.
  private var age = 0
  /// The time of day.
  private var timeOfDay = 0

  /// Lock for managing thread-safe read and write of ``chunks``, ``chunklessLightingData`` and ``unlitChunks``.
  private var terrainLock = ReadWriteLock()
  /// The world's chunks.
  private var chunks: [ChunkPosition: Chunk] = [:]
  /// Lighting data that arrived before its respective chunk or was sent for a non-existent chunk.
  private var chunklessLightingData: [ChunkPosition: ChunkLightingUpdateData] = [:]
  /// Chunks that don't have lighting data yet.
  private var unlitChunks: [ChunkPosition: Chunk] = [:]

  /// Used to update world lighting.
  private var lightingEngine = LightingEngine()

  /// Used to manage thread safe access of `_eventBus`.
  private var eventBusLock = ReadWriteLock()
  /// Not thread safe. Use `eventBus`.
  private var _eventBus: EventBus

  // MARK: Init

  /// Create an empty world.
  public init(eventBus: EventBus) {
    _eventBus = eventBus
    name = Identifier(name: "world")
    dimension = Identifier(name: "overworld")
    hashedSeed = 0
    isFlat = false
    isDebug = false
  }

  /// Create a new `World` from `World.Info`.
  public init(from descriptor: WorldDescriptor, eventBus: EventBus) {
    _eventBus = eventBus
    name = descriptor.worldName
    dimension = descriptor.dimension
    hashedSeed = descriptor.hashedSeed
    isFlat = descriptor.isFlat
    isDebug = descriptor.isDebug
  }

  // MARK: Time

  /// - Returns: The current age of the world in ticks.
  public func getAge() -> Int {
    timeLock.acquireReadLock()
    defer { timeLock.unlock() }
    return age
  }

  /// - Returns: The current time of day in ticks.
  public func getTimeOfDay() -> Int {
    timeLock.acquireReadLock()
    defer { timeLock.unlock() }
    return timeOfDay
  }

  /// Sets the age of the world in ticks.
  /// - Parameter age: The new value.
  public func setAge(_ age: Int) {
    timeLock.acquireWriteLock()
    defer { timeLock.unlock() }
    self.age = age
  }

  /// Sets the time of day in ticks.
  /// - Parameter timeOfDay: The new value.
  public func setTimeOfDay(_ timeOfDay: Int) {
    timeLock.acquireWriteLock()
    defer { timeLock.unlock() }
    self.timeOfDay = timeOfDay
  }

  // MARK: Blocks

  /// Sets the block at the specified position to the specified block id.
  ///
  /// This will trigger lighting to be updated.
  public func setBlockId(at position: BlockPosition, to state: Int) {
    if let chunk = chunk(at: position.chunk) {
      chunk.setBlockId(at: position.relativeToChunk, to: state)
      lightingEngine.updateLighting(at: position, in: self)

      eventBus.dispatch(Event.SetBlock(
        position: position,
        newState: state
      ))
    } else {
      log.warning("Cannot set block in non-existent chunk, chunkPosition=\(position.chunk)")
    }
  }

  /// Get the block id of the block at the specified position.
  /// - Parameters:
  ///   - position: A block position in world coordinates.
  ///   - acquireLock: Whether to acquire a lock or not before reading the value. Don't touch this unless you know what you're doing.
  /// - Returns: A block state id. If `position` is in a chunk that isn't loaded, `0` (regular air) is returned.
  public func getBlockId(at position: BlockPosition, acquireLock: Bool = true) -> Int {
    if Self.isValidBlockPosition(position), let chunk = chunk(at: position.chunk) {
      return chunk.getBlockId(at: position.relativeToChunk, acquireLock: acquireLock)
    } else {
      return 0
    }
  }

  /// Returns information about the type of block at the specified position.
  /// - Parameters:
  ///   - position: Position of block.
  ///   - acquireLock: Whether to acquire a lock or not before reading the value. Don't touch this unless you know what you're doing.
  /// - Returns: The block at the given position. ``Block/missing`` if the block doesn't exist.
  public func getBlock(at position: BlockPosition, acquireLock: Bool = true) -> Block {
    return RegistryStore.shared.blockRegistry.block(withId: Int(getBlockId(at: position, acquireLock: acquireLock))) ?? Block.missing
  }

  // MARK: Lighting

  /// Sets the block light level of a block. Does not propagate the change and does not verify the level is valid.
  ///
  /// If `position` is in a chunk that isn't loaded or is above y=255 or below y=0, nothing happens.
  ///
  /// - Parameters:
  ///   - position: A block position relative to the world.
  ///   - level: The new block light level. Should be from 0 to 15 inclusive. Not validated.
  public func setBlockLightLevel(at position: BlockPosition, to level: Int) {
    if let chunk = chunk(at: position.chunk) {
      chunk.setBlockLightLevel(at: position.relativeToChunk, to: level)
    }
  }

  /// Gets the block light level for the given block.
  ///
  /// - Parameter position: Position of block.
  /// - Returns: The block light level of the block. If the given position isn't loaded, ``LightLevel/defaultBlockLightLevel`` is returned.
  public func getBlockLightLevel(at position: BlockPosition) -> Int {
    if let chunk = chunk(at: position.chunk) {
      return chunk.blockLightLevel(at: position.relativeToChunk)
    } else {
      return LightLevel.defaultBlockLightLevel
    }
  }

  /// Sets the sky light level of a block. Does not propagate the change and does not verify the level is valid.
  ///
  /// If `position` is in a chunk that isn't loaded or is above y=255 or below y=0, nothing happens.
  ///
  /// - Parameters:
  ///   - position: A block position relative to the world.
  ///   - level: The new sky light level. Should be from 0 to 15 inclusive. Not validated.
  public func setSkyLightLevel(at position: BlockPosition, to level: Int) {
    if let chunk = chunk(at: position.chunk) {
      chunk.setSkyLightLevel(at: position.relativeToChunk, to: level)
    }
  }

  /// Gets the sky light level for the given block.
  ///
  /// - Parameter position: Position of block.
  /// - Returns: The sky light level of the block. If the given position isn't loaded, ``LightLevel/defaultSkyLightLevel`` is returned.
  public func getSkyLightLevel(at position: BlockPosition) -> Int {
    if let chunk = chunk(at: position.chunk) {
      return chunk.skyLightLevel(at: position.relativeToChunk)
    } else {
      return LightLevel.defaultSkyLightLevel
    }
  }

  /// Updates a chunk's lighting with lighting data received from the server.
  /// - Parameters:
  ///   - position: Position of chunk to update.
  ///   - data: Data about the lighting update.
  public func updateChunkLighting(at position: ChunkPosition, with data: ChunkLightingUpdateData) {
    terrainLock.acquireWriteLock()

    // Terrain lock is unlocked before acquiring a lock on a complete chunk, because otherwise this
    // function locks waiting for the chunk lock, and some code that already has a chunk lock (such
    // as in `ChunkSectionMeshBuilder`) but needs to wait for a terrain lock.
    if let chunk = chunks[position] {
      terrainLock.unlock()
      chunk.updateLighting(with: data)
    } else if let chunk = unlitChunks[position] {
      terrainLock.unlock()
      chunk.updateLighting(with: data)
      terrainLock.acquireWriteLock()
      unlitChunks.removeValue(forKey: position)
      chunks[position] = chunk
      eventBus.dispatch(Event.AddChunk(position: position))
      terrainLock.unlock()
    } else {
      chunklessLightingData[position] = data
      terrainLock.unlock()
    }

    eventBus.dispatch(Event.UpdateChunkLighting(
      position: position,
      data: data
    ))
  }

  // MARK: Biomes

  /// Gets the biome at the specified position.
  /// - Parameter position: Position to get biome at.
  /// - Returns: The biome at the requested position, or `nil` if the position is in a non-loaded
  ///   chunk.
  public func getBiome(at position: BlockPosition) -> Biome? {
    return chunk(at: position.chunk)?.biome(at: position.relativeToChunk)
  }

  // MARK: Chunks

  /// Gets the chunk at the specified position. Does not return unlit chunks.
  /// - Parameter chunkPosition: Position of chunk.
  /// - Returns: The requested chunk, or `nil` if the chunk isn't present.
  public func chunk(at chunkPosition: ChunkPosition) -> Chunk? {
    terrainLock.acquireReadLock()
    defer { terrainLock.unlock() }
    return chunks[chunkPosition]
  }

  /// Adds a chunk to the world.
  /// - Parameters:
  ///   - chunk: Chunk to add.
  ///   - position: Position chunk should be added at.
  public func addChunk(_ chunk: Chunk, at position: ChunkPosition) {
    terrainLock.acquireWriteLock()
    defer { terrainLock.unlock() }

    if let lightingData = chunklessLightingData.removeValue(forKey: position) {
      chunk.updateLighting(with: lightingData)
    }

    if !chunk.hasLighting {
      unlitChunks[position] = chunk
    } else {
      chunks[position] = chunk
    }

    eventBus.dispatch(Event.AddChunk(position: position))
    if chunk.hasLighting {
      eventBus.dispatch(Event.ChunkComplete(position: position))
    }
  }

  /// Removes the chunk at the specified position if present.
  /// - Parameter position: Position of chunk to remove.
  public func removeChunk(at position: ChunkPosition) {
    terrainLock.acquireWriteLock()
    defer { terrainLock.unlock() }

    chunks.removeValue(forKey: position)
    eventBus.dispatch(Event.RemoveChunk(position: position))
  }

  /// Gets the chunks neighbouring the specified chunk with their respective directions.
  ///
  /// Neighbours are any chunk that are next to the current chunk along any of the axes.
  ///
  /// - Parameter position: Position of chunk.
  /// - Returns: All present neighbours of the chunk.
  public func neighbours(ofChunkAt position: ChunkPosition) -> [CardinalDirection: Chunk] {
    let neighbourPositions = position.allNeighbours
    var neighbourChunks: [CardinalDirection: Chunk] = [:]
    for (direction, neighbourPosition) in neighbourPositions {
      if let neighbour = chunk(at: neighbourPosition) {
        neighbourChunks[direction] = neighbour
      }
    }
    return neighbourChunks
  }

  /// Gets all four neighbours of a chunk.
  ///
  /// See ``neighbours(ofChunkAt:)`` for a definition of neighbour.
  ///
  /// - Parameter chunkPosition: Position of chunk.
  /// - Returns: A value containing all 4 neighbouring chunks. `nil` if any of the neighbours are not present.
  public func allNeighbours(ofChunkAt chunkPosition: ChunkPosition) -> ChunkNeighbours? {
    let northPosition = chunkPosition.neighbour(inDirection: .north)
    let eastPosition = chunkPosition.neighbour(inDirection: .east)
    let southPosition = chunkPosition.neighbour(inDirection: .south)
    let westPosition = chunkPosition.neighbour(inDirection: .west)

    guard
      let northNeighbour = chunk(at: northPosition),
      let eastNeighbour = chunk(at: eastPosition),
      let southNeighbour = chunk(at: southPosition),
      let westNeighbour = chunk(at: westPosition)
    else {
      return nil
    }

    return ChunkNeighbours(
      north: northNeighbour,
      east: eastNeighbour,
      south: southNeighbour,
      west: westNeighbour)
  }

  /// Gets whether a chunk has been fully received.
  ///
  /// To be fully received, a chunk must be present, and must contain lighting data.
  /// - Parameter position: The position of the chunk to check.
  /// - Returns: Whether the chunk has been fully received.
  public func isChunkComplete(at position: ChunkPosition) -> Bool {
    return chunk(at: position) != nil
  }

  /// Gets whether a chunk hasn't got any lighting.
  /// - Parameter position: The position of the chunk to check.
  /// - Returns: Whether the chunk hasn't got lighting from the server. Returns `false` if the chunk doesn't exist.
  public func isChunkUnlit(at position: ChunkPosition) -> Bool {
    terrainLock.acquireReadLock()
    defer { terrainLock.unlock() }
    return unlitChunks[position] != nil
  }

  // MARK: Helper

  /// Gets whether the a position is in a loaded chunk or not.
  /// - Parameter position: Position to check.
  /// - Returns: `true` if the position is in a loaded chunk.
  public func isPositionLoaded(_ position: BlockPosition) -> Bool {
    return isChunkComplete(at: position.chunk)
  }

  /// - Parameter position: Position to validate.
  /// - Returns: whether a block position is below the world height limit and above 0.
  public static func isValidBlockPosition(_ position: BlockPosition) -> Bool {
    return position.y < Chunk.height && position.y >= 0
  }
}
