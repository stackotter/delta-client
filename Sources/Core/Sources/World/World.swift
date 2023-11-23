import Foundation
import FirebladeMath
import Logging

/// Represents a Minecraft world. Completely thread-safe.
///
/// Includes chunks, lighting and some other metadata.
public class World {
  /// The color of fog when in lava.
  public static let lavaFogColor = Vec3f(0.6, 0.1, 0)

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

  /// The name of this world.
  public let name: Identifier
  /// The world's dimension.
  public let dimension: Dimension
  /// The hashed seed of this world.
  public let hashedSeed: Int
  /// Whether this world is a debug world or not.
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
    dimension = Dimension.overworld
    hashedSeed = 0
    isFlat = false
    isDebug = false
  }

  /// Create a new world with the given properties.
  public init(
    name: Identifier,
    dimension: Dimension,
    hashedSeed: Int,
    isFlat: Bool,
    isDebug: Bool,
    eventBus: EventBus
  ) {
    _eventBus = eventBus
    self.name = name
    self.dimension = dimension
    self.hashedSeed = hashedSeed
    self.isFlat = isFlat
    self.isDebug = isDebug
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

    if let time = dimension.fixedTime {
      return time
    } else {
      // Negative time of day is used to indicate that doDaylightCycle is false (weird)
      return timeOfDay < 0 ? -timeOfDay : timeOfDay
    }
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

  // MARK: Sky

  /// Gets the sky color seen when viewed from a given position.
  /// - Parameters:
  ///   - position: The position that the world is being viewed from.
  public func getSkyColor(at position: BlockPosition) -> Vec3f {
    // TODO: Avoid the force unwrap. Possibly by updating the BiomeRegistry to ensure that
    //   a plains biome is always present to use as a default (perhaps as a defaultBiome
    //   property).
    let biome = getBiome(at: position) ??
      RegistryStore.shared.biomeRegistry.biome(for: Identifier(name: "plains"))!

    let skyColor = biome.skyColor.floatVector
    let skyBrightness = getSkyBrightness()

    return skyColor * skyBrightness
  }

  // TODO: Does this only make sense for the overworld?
  /// Gets the brightness of the sky due to the time of day.
  public func getSkyBrightness() -> Float {
    // The sun angle is used to calculate sun height, which is then adjusted to account
    // for the fact that the sun still brightens the sky for a while after it sets.
    let sunAngle = getSunAngleRadians()
    // The sun's height from `-1` at midnight to `1` at midday.
    let sunHeight = Foundation.cos(sunAngle)
    return MathUtil.clamp(sunHeight * 2 + 0.5, 0, 1)
  }

  /// Gets the sun's angle in the sky with 0 being directly overhead, and the angle increasing
  /// into the afternoon. Always in the interval `[0, 2π)`.
  public func getSunAngleRadians() -> Float {
    let time = getTimeOfDay()

    // The progress of the day starting at 6am
    let dayProgress = Float(time) / 24000
    let dayProgressSinceNoon = Foundation.fmod(dayProgress - 0.25, 1)

    // Due to modelling the world similarly to a sphere (in terms of its sky), the sun
    // should spend less time above the horizontal than below it, which this extra factor
    // takes care of.
    let dayShorteningFactor = 0.5 - Foundation.cos(dayProgressSinceNoon * .pi) / 2
    // The sun's progress around the sky from 0 to 1, with 0 being noon.
    let sunProgress = (2 * dayProgressSinceNoon + dayShorteningFactor) / 3

    return 2 * .pi * sunProgress
  }

  /// Gets the color of fog that is seen when viewed from a given position and looking
  /// in a specific direction.
  /// - Parameters:
  ///   - ray: The ray defining the position and look direction of the viewer.
  ///   - renderDistance: The render distance that the fog will be rendered at. Often
  ///     the true render distance minus 1 is used when above 2 render distance (to conceal
  ///     more of the edge of the world).
  ///   - acquireLock: Whether to acquire a lock or not before reading the value. Don't
  ///     touch this unless you know what you're doing.
  public func getFogColor(
    forViewerWithRay ray: Ray,
    withRenderDistance renderDistance: Int,
    acquireLock: Bool = true
  ) -> Vec3f {
    let position = ray.origin
    let blockPosition = BlockPosition(x: Int(position.x), y: Int(position.y), z: Int(position.z))

    let biome = getBiome(at: blockPosition)
      ?? RegistryStore.shared.biomeRegistry.biome(for: Identifier(name: "plains"))!

    let fluidOnEyes = getFluidState(at: position, acquireLock: acquireLock)
      .map(\.fluidId)
      .map(RegistryStore.shared.fluidRegistry.fluid(withId:))

    var fogColor: Vec3f
    if fluidOnEyes?.isWater == true {
      // TODO: Slowly adjust the water fog color as the player's 'eyes' adjust.
      fogColor = biome.waterFogColor.floatVector
    } else if fluidOnEyes?.isLava == true {
      fogColor = Self.lavaFogColor
    } else {
      fogColor = MathUtil.lerp(
        from: getSkyColor(at: blockPosition),
        to: biome.fogColor.floatVector,
        progress: FirebladeMath.pow(0.25 + 0.75 * min(32, Float(renderDistance)) / 32, 0.25)
      )

      // Take sky brightness into account.
      if dimension.isEnd {
        fogColor *= 0.15
      } else if dimension.isOverworld {
        let skyBrightness = getSkyBrightness()
        fogColor *= Vec3f(
          MathUtil.lerp(from: 0.06, to: 1, progress: skyBrightness),
          MathUtil.lerp(from: 0.06, to: 1, progress: skyBrightness),
          MathUtil.lerp(from: 0.09, to: 1, progress: skyBrightness)
        )
      }

      // TODO: This is actually render distance 4, but decreased by 1 to cover more terrain,
      //   move this adjustment into the fog calculation for more clarity
      if renderDistance >= 3 {
        let sunHemisphereDirection = Vec3f(
          Foundation.sin(getSunAngleRadians()) > 0 ? -1 : 1,
          0,
          0
        )
        let sunriseFogAmount = FirebladeMath.dot(ray.direction, sunHemisphereDirection)
        if sunriseFogAmount > 0 {
          switch getDaylightCyclePhase() {
            case let .sunrise(sunriseColor), let .sunset(sunriseColor):
              // The more see through the sunrise/sunset color, the less intense the directional
              // fog color is.
              let progress = sunriseFogAmount * sunriseColor.w
              let sunriseColorRGB = Vec3f(sunriseColor.x, sunriseColor.y, sunriseColor.z)
              fogColor = MathUtil.lerp(from: fogColor, to: sunriseColorRGB, progress: progress)
            case .day, .night:
              break
          }
        }
      }
    }

    // As the player nears the 
    let voidFadeStart: Float = isFlat ? 1 : 32
    if position.y < voidFadeStart {
      let amount = max(0, position.y / voidFadeStart)
      fogColor *= amount * amount 
    }

    return fogColor
  }

  /// Gets the fog experienced by a player viewing the world from a given position and looking
  /// in a specific direction.
  /// - Parameters:
  ///   - ray: The ray defining the position and look direction of the viewer.
  ///   - renderDistance: The render distance that the fog will be rendered at. Often
  ///     the true render distance minus 1 is used when above 2 render distance (to conceal
  ///     more of the edge of the world).
  ///   - acquireLock: Whether to acquire a lock or not before reading the value. Don't
  ///     touch this unless you know what you're doing.
  public func getFog(
    forViewerWithRay ray: Ray,
    withRenderDistance renderDistance: Int,
    acquireLock: Bool = true
  ) -> Fog {
    // TODO: Check fog reverse engineering document for any other adjustments
    //   to implement.
    let fogColor = getFogColor(forViewerWithRay: ray, withRenderDistance: renderDistance)

    let renderDistanceInBlocks = Float(renderDistance * Chunk.width)

    let fluidOnEyes = getFluidState(at: ray.origin, acquireLock: acquireLock)
      .map(\.fluidId)
      .map(RegistryStore.shared.fluidRegistry.fluid(withId:))

    guard fluidOnEyes?.isWater != true else {
      // TODO: Calculate density as per reverse engineering document
      return Fog(color: fogColor, style: .exponential(density: 0.05))
    }
    
    // TODO: If player has blindness, the fog starts at 5/4 and ends at 5, lerping up to
    //   starting at renderDistance/4 and ending at renderDistance over the last second of blindness

    let fogStart: Float
    let fogEnd: Float
    if fluidOnEyes?.isLava == true {
      // TODO: Should start at 0 and end at 3 if the player has fire resistance
      fogStart = 0.25
      fogEnd = 1
    } else if dimension.isNether {
      // TODO: This should also happen if there is a boss present which has the fog creation effect
      //   (determined by flags of BossBarPacket)
      fogStart = renderDistanceInBlocks / 20
      fogEnd = min(96, renderDistanceInBlocks / 2)
    } else {
      fogStart = 0.75 * renderDistanceInBlocks
      fogEnd = renderDistanceInBlocks
    }

    return Fog(
      color: fogColor,
      style: .linear(startDistance: fogStart, endDistance: fogEnd)
    )
  }

  /// Gets the phase of the daylight cycle (sunrise, sunset, etc.).
  ///
  /// The color associated with sunrises and sunsets changes constantly throughout
  /// that phase of the daylight cycle. To get the latest color you must call this
  /// method again.
  public func getDaylightCyclePhase() -> DaylightCyclePhase {
    let sunAngleRadians = getSunAngleRadians()
    let sunHeight = Foundation.cos(sunAngleRadians)
    if sunHeight < -0.4 {
      return .night
    } else if sunHeight > 0.4 {
      return .day
    } else {
      // The sunrise or sunset's current brightness from 0 to 1 (not true brightness,
      // but it is correlated with actual brightness).
      let brightnessFactor = sunHeight / 0.4 * 0.5 + 0.5
      let sqrtAlpha = 0.01 + 0.99 * Foundation.sin(brightnessFactor * .pi)
      let color = Vec4f(
        brightnessFactor * 0.3 + 0.7,
        brightnessFactor * brightnessFactor * 0.7 + 0.2,
        0.2,
        sqrtAlpha * sqrtAlpha
      )

      let isSunrise = Foundation.sin(sunAngleRadians) < 0
      if isSunrise {
        return .sunrise(color: color)
      } else {
        return .sunset(color: color)
      }
    }
  }

  /// Gets the phase of the moon (an integer in the range `0..<8`). The moon's
  /// phase progresses by 1 each day.
  public func getMoonPhase() -> Int {
    (getTimeOfDay() / 24000) % 8
  }

  /// Gets the brightness of the stars in the current dimension at the current time.
  public func getStarBrightness() -> Float {
    guard dimension.isOverworld else {
      return 0
    }

    let brightness = 0.75 - 2 * Foundation.cos(getSunAngleRadians())
    let clampedBrightness = MathUtil.clamp(brightness, 0, 1)
    return clampedBrightness * clampedBrightness / 2
  }

  // MARK: Blocks

  /// Sets the block at the specified position to the specified block id.
  ///
  /// This will trigger lighting to be updated.
  public func setBlockId(at position: BlockPosition, to state: Int) {
    if let chunk = chunk(at: position.chunk) {
      chunk.setBlockId(at: position.relativeToChunk, to: state)
      lightingEngine.updateLighting(at: position, in: self)

      eventBus.dispatch(Event.SingleBlockUpdate(
        position: position,
        newState: state
      ))
    } else {
      log.warning("Cannot set block in non-existent chunk, chunkPosition=\(position.chunk)")
    }
  }

  /// Sets the blocks at the specified positions to the specified block ids.
  ///
  /// Using this method is preferred over just using setBlockId within a for loop because it
  /// processes lighting updates in batch which is much more efficient.
  /// - Parameters:
  ///   - updates: The positions and new states of affected blocks.
  ///   - chunkPosition: If all updates occur within a single chunk provide this parameter for more
  ///     efficient batching.
  public func processMultiBlockUpdate(
    _ updates: [Event.SingleBlockUpdate],
    inChunkAt chunkPosition: ChunkPosition? = nil
  ) {
    if let chunkPosition = chunkPosition {
      if let chunk = chunk(at: chunkPosition) {
        for update in updates {
          chunk.setBlockId(at: update.position.relativeToChunk, to: update.newState)
        }
        lightingEngine.updateLighting(at: updates.map(\.position), in: self)
      } else {
        log.warning("Cannot handle multi-block change in non-existent chunk, chunkPosition=\(chunkPosition)")
        return
      }
    } else {
      for update in updates {
        if let chunk = chunk(at: update.position.chunk) {
          chunk.setBlockId(at: update.position.relativeToChunk, to: update.newState)
        } else {
          log.warning("Cannot handle multi-block change in non-existent chunk, chunkPosition=\(update.position.chunk)")
          return
        }
      }
      lightingEngine.updateLighting(at: updates.map(\.position), in: self)
    }

    eventBus.dispatch(Event.MultiBlockUpdate(updates: updates))
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

  // TODO: Should these getters be called `block(at:)` etc instead?
  /// Returns information about the type of block at the specified position.
  /// - Parameters:
  ///   - position: Position of block.
  ///   - acquireLock: Whether to acquire a lock or not before reading the value. Don't touch this unless you know what you're doing.
  /// - Returns: The block at the given position. ``Block/missing`` if the block doesn't exist.
  public func getBlock(at position: BlockPosition, acquireLock: Bool = true) -> Block {
    let blockId = getBlockId(at: position, acquireLock: acquireLock)
    return RegistryStore.shared.blockRegistry.block(withId: blockId) ?? Block.missing
  }

  /// Returns information about the fluid state at the specified position.
  /// - Parameters:
  ///   - position: Position of fluid.
  ///   - acquireLock: Whether to acquire a lock or not before reading the value. Don't touch this unless you know what you're doing.
  /// - Returns: The fluid state at the given position, if any.
  public func getFluidState(at position: BlockPosition, acquireLock: Bool = true) -> FluidState? {
    let block = getBlock(at: position)
    return block.fluidState
  }

  /// Returns information about the type of fluid that the given point is in.
  /// - Parameters:
  ///   - position: Point to get fluid at.
  ///   - acquireLock: Whether to acquire a lock or not before reading the value. Don't touch this unless you know what you're doing.
  /// - Returns: The fluid at the given point, if any.
  public func getFluidState(at position: Vec3f, acquireLock: Bool = true) -> FluidState? {
    let blockPosition = BlockPosition(x: Int(position.x), y: Int(position.y), z: Int(position.z))
    guard let fluidState = getFluidState(at: blockPosition) else {
      return nil
    }

    let fluidStateAbove = getFluidState(at: blockPosition.neighbour(.up))
    if fluidStateAbove?.fluidId == fluidState.fluidId {
      return fluidState
    }

    let height = Float(fluidState.height + 1) / 9
    let fluidEnd = Float(blockPosition.y) + height
    if position.y <= fluidEnd {
      return fluidState
    } else {
      return nil
    }
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

    if chunk.hasLighting {
      eventBus.dispatch(Event.AddChunk(position: position))
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
      west: westNeighbour
    )
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
    return isChunkComplete(at: position.chunk) && Self.isValidBlockPosition(position)
  }

  /// - Parameter position: Position to validate.
  /// - Returns: whether a block position is below the world height limit and above 0.
  public static func isValidBlockPosition(_ position: BlockPosition) -> Bool {
    return position.y < Chunk.height && position.y >= 0
  }
}
