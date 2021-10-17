import Foundation
import Collections

// The algorithm used in this lighting engine is a simplified version of the one found in
// Starlight, a highly optimised replacement for the vanilla lighting system.
// https://github.com/PaperMC/Starlight/tree/fabric

// TODO: Handle conditionally transparent blocks (i.e. slabs and stairs)

/// The engine used to update lighting of worlds when blocks change. Implementation is based of Starlight.
public struct LightingEngine {
  /// Queue of blocks to check for increasing light levels. Contains position of block, light level of block,
  /// extra instructions to perform before the usual increase check, and directions to skip checking in.
  private var increaseQueue: Deque<(Position, Int, IncreaseFlags, [Direction])> = []
  /// Queue of blocks to check for decreasing light levels. Contains position of block, light level of block,
  /// and directions to skip checking in.
  private var decreaseQueue: Deque<(Position, Int, [Direction])> = []
  
  /// Create a new lighting engine instance with its own queues.
  public init() { }
  
  /// Propagates lighting changes from an updated block. `position` is in world coordinates.
  public mutating func updateLighting(at position: Position, in world: World) {
    increaseQueue = []
    decreaseQueue = []
    updateLighting(at: [position], in: world)
  }
  
  /// Propagates lighting changes from multiple updated blocks. `positions` are in world coordinates.
  public mutating func updateLighting(at positions: [Position], in world: World) {
    updateBlockLight(at: positions, in: world)
    updateSkyLight(at: positions, in: world)
  }
  
  /// Propagates block light changes from multiple updated blocks. `positions` are in world coordinates.
  private mutating func updateBlockLight(at positions: [Position], in world: World) {
    for position in positions {
      queueBlockLightUpdate(at: position, in: world)
    }
    
    performLightLevelDecrease(
      in: world,
      getLightLevel: world.getBlockLightLevel(at:),
      setLightLevel: world.setBlockLightLevel(at:to:))
  }
  
  /// Propagates sky light changes from multiple updated blocks. `positions` are in world coordinates.
  ///
  /// All positions provided must be in existent chunks.
  private mutating func updateSkyLight(at positions: [Position], in world: World) {
    for position in positions {
      guard let highest = world.chunk(at: position.chunk)?.heightMap.getHighestLightBlocking(position.relativeToChunk) else {
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
            increaseQueue.append((position, 15, [], [.up, .down]))
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
            decreaseQueue.append((position, currentLightLevel, []))
          }
        }
      }
      
      queueSkyLightUpdate(at: position, in: world)
    }
    
    performLightLevelDecrease(
      in: world,
      getLightLevel: world.getSkyLightLevel(at:),
      setLightLevel: world.setSkyLightLevel(at:to:))
  }
  
  /// Checks an updated block and queues any block light level propagation required.
  private mutating func queueBlockLightUpdate(at position: Position, in world: World) {
    let currentLightLevel = world.getBlockLightLevel(at: position)
    let block = world.getBlock(at: position)
    let emittedLight = block.lightMaterial.luminance
    
    world.setBlockLightLevel(at: position, to: emittedLight)
    
    if emittedLight != 0 {
      increaseQueue.append((position, emittedLight, [], []))
    }
    
    decreaseQueue.append((position, currentLightLevel, []))
  }
  
  /// Checks an updated block and queues any sky light level propagation required.
  private mutating func queueSkyLightUpdate(at position: Position, in world: World) {
    let currentLightLevel = world.getSkyLightLevel(at: position)
    
    if currentLightLevel == 15 {
      increaseQueue.append((position, 15, [], []))
    } else {
      world.setSkyLightLevel(at: position, to: 0)
    }
    
    decreaseQueue.append((position, currentLightLevel, []))
  }
  
  private mutating func performLightLevelIncrease(
    in world: World,
    getLightLevel: (_ position: Position) -> Int,
    setLightLevel: (_ position: Position, _ level: Int) -> Void
  ) {
    while let (position, light, flags, skipDirections) = increaseQueue.popFirst() {
      if flags.contains(.writeLevel) {
        setLightLevel(position, light)
      }
      
      if flags.contains(.recheckLevels) {
        if getLightLevel(position) != light {
          continue
        }
      }
      
      for direction in Direction.allDirections where !skipDirections.contains(direction) {
        let neighbourPosition = position + direction.intVector
        
        if !world.isPositionLoaded(neighbourPosition) {
          continue
        }
        
        let neighbourLight = getLightLevel(neighbourPosition)
        
        if neighbourLight >= light {
          continue
        }
        
        let neighbourBlock = world.getBlock(at: neighbourPosition)
        let opacity = max(neighbourBlock.lightMaterial.opacity, 1)
        let newNeighbourLight = max(light - opacity, 0)
        
        if newNeighbourLight > neighbourLight {
          setLightLevel(neighbourPosition, newNeighbourLight)
          
          if newNeighbourLight > 1 {
            increaseQueue.append((neighbourPosition, newNeighbourLight, [], [direction.opposite]))
          }
        }
      }
    }
  }
  
  private mutating func performLightLevelDecrease(
    in world: World,
    getLightLevel: (_ position: Position) -> Int,
    setLightLevel: (_ position: Position, _ level: Int) -> Void
  ) {
    while let (position, propagatedLight, skipDirections) = decreaseQueue.popFirst() {
      for direction in Direction.allDirections where !skipDirections.contains(direction) {
        let neighbourPosition = position + direction.intVector
        
        if !world.isPositionLoaded(neighbourPosition) {
          continue
        }
        
        let neighbourLight = getLightLevel(neighbourPosition)
        
        if neighbourLight == 0 {
          continue
        }
        
        let neighbourBlock = world.getBlock(at: neighbourPosition)
        let opacity = max(neighbourBlock.lightMaterial.opacity, 1)
        let newNeighbourLight = max(propagatedLight - opacity, 0)
        
        if neighbourLight > newNeighbourLight {
          increaseQueue.append((neighbourPosition, neighbourLight, [.recheckLevels], []))
          continue
        }
        
        let neighbourLuminance = neighbourBlock.lightMaterial.luminance
        if neighbourLuminance != 0 {
          increaseQueue.append((neighbourPosition, neighbourLuminance, [.writeLevel], []))
        }
        
        setLightLevel(neighbourPosition, neighbourLuminance)
        
        if newNeighbourLight > 0 {
          decreaseQueue.append((neighbourPosition, newNeighbourLight, [direction.opposite]))
        }
      }
    }
    
    performLightLevelIncrease(in: world, getLightLevel: getLightLevel, setLightLevel: setLightLevel)
  }
}

extension LightingEngine {
  /// Flags for entries in the increase queue.
  private struct IncreaseFlags: OptionSet {
    var rawValue: UInt8
    
    init(rawValue: UInt8) {
      self.rawValue = rawValue
    }
    
    static let writeLevel = IncreaseFlags(rawValue: 1)
    static let recheckLevels = IncreaseFlags(rawValue: 2)
  }
}
