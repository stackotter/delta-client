import Foundation

/// The height map for a chunk.
///
/// Keeps track of both the highest block and the highest block that can block sky light in
/// each column of a chunk. When propagating sky light levels, direct sunlight is transmitted
/// fully by any block with an opacity of 0. The skyLightBlockingHeightMap is used to speed
/// up sky lighting updates.
public struct HeightMap {
  /// The highest block in each column of the chunk.
  public var heightMap: [Int]
  /// The highest block with a non-zero opacity in each column of the chunk.
  public var skyLightBlockingHeightMap: [Int]
  
  /// Creates a new height map with the given initial height maps.
  public init(heightMap: [Int], skyLightBlockingHeightMap: [Int]) {
    self.heightMap = heightMap
    self.skyLightBlockingHeightMap = skyLightBlockingHeightMap
  }
  
  public func getHighest(_ x: Int, _ z: Int) -> Int {
    return heightMap[columnIndex(x, z)]
  }
  
  public func getHighest(_ position: Position) -> Int {
    return heightMap[columnIndex(position)]
  }
  
  public func getHighestLightBlocking(_ x: Int, _ z: Int) -> Int {
    return skyLightBlockingHeightMap[columnIndex(x, z)]
  }
  
  public func getHighestLightBlocking(_ position: Position) -> Int {
    return skyLightBlockingHeightMap[columnIndex(position)]
  }
  
  /// Updates the height maps with regards to the given block update.
  ///
  /// The block should already be updated in the chunk.
  public mutating func handleBlockUpdate(at position: Position, in chunk: Chunk, acquireChunkLock: Bool = true) {
    let newBlock = chunk.getBlock(at: position, acquireLock: acquireChunkLock)
    let columnIndex = self.columnIndex(position)
    let highestBlock = heightMap[columnIndex]
    
    // Update heightMap
    if position.y > highestBlock {
      if newBlock.className != "AirBlock" {
        heightMap[columnIndex] = Int(position.y)
      }
    } else if position.y == highestBlock && newBlock.className == "AirBlock" {
      // If the highest block has changed to air, search below for the next highest block
      var position = position
      var foundBlock = false
      for _ in 0..<position.y {
        position.y -= 1
        let block = chunk.getBlock(at: position, acquireLock: acquireChunkLock)
        if block.className != "AirBlock" {
          heightMap[columnIndex] = Int(position.y)
          foundBlock = true
          break
        }
      }
      
      // If the column is empty set the height to -1
      if !foundBlock {
        heightMap[columnIndex] = -1
      }
    }
    
    // Update skyLightBlockingHeightMap
    let highestLightBlockingBlock = skyLightBlockingHeightMap[columnIndex]
    if position.y > highestLightBlockingBlock {
      if newBlock.lightMaterial.opacity != 0 {
        skyLightBlockingHeightMap[columnIndex] = Int(position.y)
      }
    } else if position.y == highestLightBlockingBlock && newBlock.lightMaterial.opacity == 0 {
      // If the highest block has changed and doesn't block direct sky light anymore, find the next highest valid block
      var position = position
      var foundBlock = false
      for _ in 0..<position.y {
        position.y -= 1
        let block = chunk.getBlock(at: position, acquireLock: acquireChunkLock)
        if block.lightMaterial.opacity != 0 {
          skyLightBlockingHeightMap[columnIndex] = Int(position.y)
          foundBlock = true
          break
        }
      }
      
      // If the column is empty set the height to -1
      if !foundBlock {
        skyLightBlockingHeightMap[columnIndex] = -1
      }
    }
  }
  
  private func columnIndex(_ position: Position) -> Int {
    return columnIndex(position.x, position.z)
  }
  
  private func columnIndex(_ x: Int, _ z: Int) -> Int {
    return Int(z * 16 + x)
  }
}
