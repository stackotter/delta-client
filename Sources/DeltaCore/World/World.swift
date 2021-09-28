import Foundation
import simd

/// A type for holding all of a world's data such as chunks and lighting.
public class World {
  /// The name of this world
  public var name: Identifier
  /// The dimension data for this world
  public var dimension: Identifier
  /// The hashed seed of this world
  public var hashedSeed: Int
  /// Whether this world is a debug world or not
  public var isDebug: Bool
  /// Whether this world is superflat or not.
  public var isFlat: Bool
  
  /// The world's chunks.
  public var chunks: [ChunkPosition: Chunk] = [:]
  /// The number of currently loaded chunks in this world for this client.
  public var chunkCount: Int {
    return chunks.count
  }
  
  /// The world's age.
  public private(set) var age: Int = 0
  /// The time of day.
  public private(set) var timeOfDay: Int = 0
  /// Whether this world is still downloading terrain.
  public private(set) var downloadingTerrain = true
  
  /// Lighting data that arrived before its respective chunk or was sent for a non-existent chunk.
  private var chunklessLightingData: [ChunkPosition: ChunkLightingUpdateData] = [:]
  
  /// Whether world updates should be handled in batches or as they arrive.
  private var batchingEnabled: Bool
  /// The current batch of world updates.
  public var eventBatch = EventBatch()
  
  private var blockRegistry: BlockRegistry
  
  private var lightingEngine = LightingEngine()
  
  /// Creates a new `World` from `World.Info`.
  public init(from descriptor: WorldDescriptor, blockRegistry: BlockRegistry, batching: Bool = false) {
    name = descriptor.worldName
    dimension = descriptor.dimension
    hashedSeed = descriptor.hashedSeed
    isFlat = descriptor.isFlat
    isDebug = descriptor.isDebug
    self.blockRegistry = blockRegistry
    self.batchingEnabled = batching
  }
  
  /// Updates the world's properties to match the supplied descriptor.
  public func update(with descriptor: WorldDescriptor) {
    name = descriptor.worldName
    dimension = descriptor.dimension
    hashedSeed = descriptor.hashedSeed
    isFlat = descriptor.isFlat
    isDebug = descriptor.isDebug
  }
  
  /// Updates the world's time to match a `TimeUpdatePacket`.
  public func updateTime(with packet: TimeUpdatePacket) {
    age = packet.worldAge
    timeOfDay = packet.timeOfDay
  }
  
  // MARK: Batching
  
  /// Enable handling updates in batches.
  public func enableBatching() {
    batchingEnabled = true
    eventBatch = EventBatch()
  }
  
  /// Enable handling updates as they arrive.
  public func disableBatching() {
    batchingEnabled = false
  }
  
  /// Process the current batch of events. Events that are filtered
  /// out are not processed and are put into the next batch.
  ///
  /// - Returns: All accepted events after processing them.
  public func processBatch(filter: ((DeltaCore.Event) -> Bool)? = nil) -> [DeltaCore.Event] {
    // Copy and clear current batch
    let batch = eventBatch
    eventBatch = EventBatch()
    
    // Filter events if a filter was specified
    var acceptedEvents: [DeltaCore.Event] = batch.events
    if let filter = filter {
      acceptedEvents = acceptedEvents.filter(filter)
      
      // Add rejected events to next batch
      let rejectedEvents = batch.events.filter({ !filter($0) })
      rejectedEvents.forEach { eventBatch.add($0) }
    }
    
    // Process accepted events
    acceptedEvents.forEach { event in
      handle(event)
    }
    
    return acceptedEvents
  }
  
  /// Handles a world event.
  public func handle(_ event: DeltaCore.Event) {
    switch event {
      case let event as Event.SetBlock:
        setBlockStateId(at: event.position, to: event.newState, bypassBatching: true)
      case let event as Event.AddChunk:
        addChunk(event.chunk, at: event.position, bypassBatching: true)
      case let event as Event.RemoveChunk:
        removeChunk(at: event.position, bypassBatching: true)
      case let event as Event.UpdateChunkLighting:
        updateChunkLighting(at: event.position, with: event.data, bypassBatching: true)
      default:
        break
    }
  }
  
  // MARK: Blocks
  
  /// Sets the block at the specified position to the specified block state.
  ///
  /// This will trigger lighting to be updated. If bypassBatching is true then
  /// the event is processed straight away.
  public func setBlockStateId(at position: Position, to state: UInt16, bypassBatching: Bool = false) {
    if batchingEnabled && !bypassBatching {
      let event = Event.SetBlock(
        position: position,
        newState: state)
      eventBatch.add(event)
    } else if let chunk = chunk(at: position.chunk) {
      chunk.setBlockStateId(at: position.relativeToChunk, to: state)
      lightingEngine.updateLighting(at: position, in: self)
    } else {
      log.warning("Cannot set block in non-existent chunk, chunkPosition=\(position.chunk)")
    }
  }
  
  /// Returns the block state id of the block at the specified position.
  public func getBlockStateId(at position: Position) -> UInt16 {
    if let chunk = chunk(at: position.chunk), Self.isValidBlockPosition(position) {
      return chunk.getBlockStateId(at: position.relativeToChunk)
    } else {
      return 0 // TODO: do not just default to air
    }
  }
  
  /// Returns information about the type of block at the specified position.
  public func getBlock(at position: Position) -> Block {
    return blockRegistry.getBlock(withId: Int(getBlockStateId(at: position))) ?? Block.missing
  }
  
  /// Returns information about the state of the block at the specified position.
  public func getBlockState(at position: Position) -> BlockState {
    return blockRegistry.getBlockState(withId: Int(getBlockStateId(at: position))) ?? BlockState.missing
  }
  
  // MARK: Lighting (no batching)
  
  /// Sets the block light level for the given block. Does not batch, does not propagate the change and does not verify the level is valid.
  public func setBlockLightLevel(at position: Position, to level: Int) {
    if let chunk = self.chunk(at: position.chunk) {
      chunk.lighting.setBlockLightLevel(at: position.relativeToChunk, to: level)
    }
  }
  
  /// Returns the block light level for the given block.
  public func getBlockLightLevel(at position: Position) -> Int {
    if let chunk = self.chunk(at: position.chunk) {
      return chunk.lighting.getBlockLightLevel(at: position.relativeToChunk)
    } else {
      return LightLevel.defaultBlockLightLevel
    }
  }
  
  /// Sets the sky light level for the given block. Does not batch, does not propagate the change and does not verify the level is valid.
  public func setSkyLightLevel(at position: Position, to level: Int) {
    if let chunk = self.chunk(at: position.chunk) {
      chunk.lighting.setSkyLightLevel(at: position.relativeToChunk, to: level)
    }
  }
  
  /// Returns the sky light level for the given block.
  public func getSkyLightLevel(at position: Position) -> Int {
    if let chunk = self.chunk(at: position.chunk) {
      return chunk.lighting.getSkyLightLevel(at: position.relativeToChunk)
    } else {
      return LightLevel.defaultSkyLightLevel
    }
  }
  
  // MARK: Chunks
  
  /// Returns the chunk at the specified position if present.
  public func chunk(at chunkPosition: ChunkPosition) -> Chunk? {
    return chunks[chunkPosition]
  }
  
  /// Returns the chunks neighbouring the specified chunk with their respective directions.
  public func neighbours(ofChunkAt chunkPosition: ChunkPosition) -> [CardinalDirection: Chunk] {
    let neighbourPositions = chunkPosition.allNeighbours
    var neighbourChunks: [CardinalDirection: Chunk] = [:]
    for (direction, neighbourPosition) in neighbourPositions {
      if let neighbour = chunk(at: neighbourPosition) {
        neighbourChunks[direction] = neighbour
      }
    }
    return neighbourChunks
  }
  
  /// Adds a chunk to the world. If bypassBatching is true then the event is processed straight away.
  public func addChunk(_ chunk: Chunk, at position: ChunkPosition, bypassBatching: Bool = false) {
    if batchingEnabled && !bypassBatching {
      let event = Event.AddChunk(position: position, chunk: chunk)
      eventBatch.add(event)
    } else {
      if let lightingData = chunklessLightingData.removeValue(forKey: position) {
        chunk.lighting.update(with: lightingData)
      }
      chunks[position] = chunk
    }
  }
  
  /// Updates a chunk's lighting with lighting data received from the server.
  /// If bypassBatching is true then the event is processed straight away.
  public func updateChunkLighting(at position: ChunkPosition, with data: ChunkLightingUpdateData, bypassBatching: Bool = false) {
    if batchingEnabled && !bypassBatching {
      let event = Event.UpdateChunkLighting(position: position, data: data)
      eventBatch.add(event)
    } else if let chunk = chunk(at: position) {
      chunk.lighting.update(with: data)
    } else {
      // Most likely the chunk just hasn't unpacked yet so wait for that
      chunklessLightingData[position] = data // TODO: concurrent access happens here, fix it
    }
  }
  
  /// Removes the chunk at the specified position if present.
  /// If bypassBatching is true then the event is processed straight away.
  public func removeChunk(at position: ChunkPosition, bypassBatching: Bool = false) {
    let event = Event.RemoveChunk(position: position)
    if batchingEnabled && !bypassBatching {
      eventBatch.add(event)
    } else {
      self.chunks.removeValue(forKey: position)
    }
  }
  
  /// Returns whether a chunk is present and has its lighting or not.
  public func chunkComplete(at position: ChunkPosition) -> Bool {
    if let chunk = chunk(at: position) {
      return chunk.lighting.isPopulated
    }
    return false
  }
  
  /// Returns whether the given position is in a loaded chunk or not.
  public func isPositionLoaded(_ position: Position) -> Bool {
    return chunkComplete(at: position.chunk)
  }
  
  /// Returns whether a block position is below the world height limit and above 0.
  public static func isValidBlockPosition(_ position: Position) -> Bool {
    return position.y < Chunk.height && position.y >= 0
  }
}
