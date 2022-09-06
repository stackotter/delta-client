import Foundation
import Collections

/// The engine used to update a world's lighting data when a block changes.
///
/// The algorithm used in this lighting engine is a simplified version of the one found in
/// [Starlight](https://github.com/PaperMC/Starlight/tree/fabric), a highly optimised replacement for the vanilla lighting system.
public struct LightingEngine {
  // MARK: Private types

  /// An entry in the increase queue.
  private struct IncreaseQueueEntry {
    var position: BlockPosition
    var lightLevel: Int
    var flags: IncreaseFlags
    var skipDirections: [Direction]
  }

  /// An entry in the decrease queue.
  private struct DecreaseQueueEntry {
    var position: BlockPosition
    var lightLevel: Int
    var skipDirections: [Direction]
  }

  /// Flags for entries in the increase queue.
  private struct IncreaseFlags: OptionSet {
    var rawValue: UInt8

    init(rawValue: UInt8) {
      self.rawValue = rawValue
    }

    static let writeLevel = IncreaseFlags(rawValue: 1)
    static let recheckLevels = IncreaseFlags(rawValue: 2)
  }

  // MARK: Private properties

  /// Queue of blocks to check when increasing light levels.
  private var increaseQueue: Deque<IncreaseQueueEntry> = []
  /// Queue of blocks to check when decreasing light levels.
  private var decreaseQueue: Deque<DecreaseQueueEntry> = []

  // MARK: Init

  /// Create a new lighting engine instance with its own queues.
  public init() { }

  // MARK: Public methods

  /// Propagates lighting changes from an updated block. `position` is in world coordinates.
  public mutating func updateLighting(at position: BlockPosition, in world: World) {
    updateLighting(at: [position], in: world)
  }

  /// Propagates lighting changes from multiple updated blocks. `positions` are in world coordinates.
  public mutating func updateLighting(at positions: [BlockPosition], in world: World) {
    increaseQueue = []
    decreaseQueue = []
    updateBlockLight(at: positions, in: world)
    updateSkyLight(at: positions, in: world)
  }

  // MARK: Private methods

  /// Propagates block light changes from multiple updated blocks. `positions` are in world coordinates.
  private mutating func updateBlockLight(at positions: [BlockPosition], in world: World) {
    for position in positions {
      queueBlockLightUpdate(at: position, in: world)
    }

    performLightLevelDecrease(
      in: world,
      getLightLevel: world.getBlockLightLevel(at:),
      setLightLevel: world.setBlockLightLevel(at:to:)
    )
  }

  /// Propagates sky light changes from multiple updated blocks. `positions` are in world coordinates.
  ///
  /// All positions provided must be in existent chunks.
  private mutating func updateSkyLight(at positions: [BlockPosition], in world: World) {
    for position in positions {
      let chunkRelativePosition = position.relativeToChunk
      guard let highest = world.chunk(at: position.chunk)?.highestLightBlockingBlock(atX: chunkRelativePosition.x, andZ: chunkRelativePosition.z) else {
        log.error("Sky light update attempted in non-existent chunk")
        return
      }

      if position.y > highest {
        // This could possibly have changed from a block that used to be the highest so update the light level 15 blocks below accordingly
        var position = position
        for _ in 0..<position.y {
          position.y -= 1
          if world.getBlock(at: position).lightMaterial.opacity == 0 && world.getSkyLightLevel(at: position) != 15 {
            world.setSkyLightLevel(at: position, to: 15)
            increaseQueue.append(IncreaseQueueEntry(position: position, lightLevel: 15, flags: [], skipDirections: [.up, .down]))
          } else {
            break
          }
        }
      } else if position.y == highest {
        // This could possibly be a new highest block so we must check the blocks below.
        var position = position
        for _ in 0..<position.y {
          position.y -= 1
          let currentLightLevel = world.getSkyLightLevel(at: position)
          if world.getBlock(at: position).lightMaterial.opacity == 0 && currentLightLevel == 15 {
            world.setSkyLightLevel(at: position, to: 0)
            decreaseQueue.append(DecreaseQueueEntry(position: position, lightLevel: currentLightLevel, skipDirections: []))
          }
        }
      }

      queueSkyLightUpdate(at: position, in: world)
    }

    performLightLevelDecrease(
      in: world,
      getLightLevel: world.getSkyLightLevel(at:),
      setLightLevel: world.setSkyLightLevel(at:to:)
    )
  }

  /// Checks an updated block and queues any block light level propagation required.
  private mutating func queueBlockLightUpdate(at position: BlockPosition, in world: World) {
    let currentLightLevel = world.getBlockLightLevel(at: position)
    let block = world.getBlock(at: position)
    let emittedLight = block.lightMaterial.luminance

    world.setBlockLightLevel(at: position, to: emittedLight)

    if emittedLight != 0 {
      increaseQueue.append(IncreaseQueueEntry(position: position, lightLevel: emittedLight, flags: [], skipDirections: []))
    }

    decreaseQueue.append(DecreaseQueueEntry(position: position, lightLevel: currentLightLevel, skipDirections: []))
  }

  /// Checks an updated block and queues any sky light level propagation required.
  private mutating func queueSkyLightUpdate(at position: BlockPosition, in world: World) {
    let currentLightLevel = world.getSkyLightLevel(at: position)

    if currentLightLevel == 15 {
      increaseQueue.append(IncreaseQueueEntry(position: position, lightLevel: 15, flags: [], skipDirections: []))
    } else {
      world.setSkyLightLevel(at: position, to: 0)
    }

    decreaseQueue.append(DecreaseQueueEntry(position: position, lightLevel: currentLightLevel, skipDirections: []))
  }

  private mutating func performLightLevelIncrease(
    in world: World,
    getLightLevel: (_ position: BlockPosition) -> Int,
    setLightLevel: (_ position: BlockPosition, _ level: Int) -> Void
  ) {
    while let entry = increaseQueue.popFirst() {
      if entry.flags.contains(.recheckLevels) {
        if getLightLevel(entry.position) != entry.lightLevel {
          continue
        }
      } else if entry.flags.contains(.writeLevel) {
        setLightLevel(entry.position, entry.lightLevel)
      }

      for direction in Direction.allDirections where !entry.skipDirections.contains(direction) {
        let neighbourPosition = entry.position + direction.intVector

        if !world.isPositionLoaded(neighbourPosition) {
          continue
        }

        let neighbourLight = getLightLevel(neighbourPosition)

        if neighbourLight >= entry.lightLevel {
          continue
        }

        let neighbourBlock = world.getBlock(at: neighbourPosition)
        let opacity = max(neighbourBlock.lightMaterial.opacity, 1)
        let newNeighbourLight = max(entry.lightLevel - opacity, 0)

        if newNeighbourLight > neighbourLight {
          setLightLevel(neighbourPosition, newNeighbourLight)

          if newNeighbourLight > 1 {
            increaseQueue.append(
              IncreaseQueueEntry(
                position: neighbourPosition,
                lightLevel: newNeighbourLight,
                flags: [],
                skipDirections: [direction.opposite]
              )
            )
          }
        }
      }
    }
  }

  private mutating func performLightLevelDecrease(
    in world: World,
    getLightLevel: (_ position: BlockPosition) -> Int,
    setLightLevel: (_ position: BlockPosition, _ level: Int) -> Void
  ) {
    while let entry = decreaseQueue.popFirst() {
      for direction in Direction.allDirections where !entry.skipDirections.contains(direction) {
        let neighbourPosition = entry.position + direction.intVector

        if !world.isPositionLoaded(neighbourPosition) {
          continue
        }

        let neighbourLight = getLightLevel(neighbourPosition)

        if neighbourLight == 0 {
          continue
        }
let neighbourBlock = world.getBlock(at: neighbourPosition)
        let opacity = max(neighbourBlock.lightMaterial.opacity, 1)
        let newNeighbourLight = max(entry.lightLevel - opacity, 0)

        if neighbourLight > newNeighbourLight {
          increaseQueue.append(IncreaseQueueEntry(position: neighbourPosition, lightLevel: neighbourLight, flags: [.recheckLevels], skipDirections: []))
          continue
        }

        let neighbourLuminance = neighbourBlock.lightMaterial.luminance
        if neighbourLuminance != 0 {
          increaseQueue.append(IncreaseQueueEntry(position: neighbourPosition, lightLevel: neighbourLuminance, flags: [.writeLevel], skipDirections: []))
        }

        setLightLevel(neighbourPosition, neighbourLuminance)

        if newNeighbourLight > 0 {
          decreaseQueue.append(DecreaseQueueEntry(position: neighbourPosition, lightLevel: newNeighbourLight, skipDirections: [direction.opposite]))
        }
      }
    }

    performLightLevelIncrease(in: world, getLightLevel: getLightLevel, setLightLevel: setLightLevel)
  }
}
