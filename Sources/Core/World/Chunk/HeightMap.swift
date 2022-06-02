/// The height map for a chunk.
///
/// Only used for lighting and as such it holds the height of the highest non-transparent block in each column.
/// Not the height of highest visible block as might be expected.
public struct HeightMap {
  /// The highest block with a non-zero opacity in each column of the chunk.
  public var heightMap: [Int]
  
  /// Creates a new height map.
  /// - Parameter heightMap: The height for each column of the chunk in order of increasing x and then increasing z.
  public init(heightMap: [Int]) {
    self.heightMap = heightMap
  }
  
  /// Gets the highest non-transparent block in the specified column.
  /// - Parameters:
  ///   - x: The x coordinate of the column.
  ///   - z: The z coordinate of the column.
  /// - Returns: The height of the highest non-transparent block in the specified column. Returns `-1` for a fully empty column.
  public func getHighestLightBlockingBlock(_ x: Int, _ z: Int) -> Int {
    return heightMap[columnIndex(x, z)]
  }
  
  /// Gets the highest non-transparent block in the specified column.
  /// - Parameters:
  ///   - position: The position of a block in the column to check.
  /// - Returns: The height of the highest non-transparent block in the specified column. Returns `-1` for a fully empty column.
  public func getHighestLightBlockingBlock(_ position: BlockPosition) -> Int {
    return heightMap[columnIndex(position)]
  }

  /// Updates the height maps with regards to the given block update.
  ///
  /// The block should already be updated in the chunk.
  public mutating func handleBlockUpdate(at position: BlockPosition, in chunk: Chunk, acquireChunkLock: Bool = true) {
    let newBlock = chunk.getBlock(at: position, acquireLock: acquireChunkLock)
    let columnIndex = self.columnIndex(position)
    
    let highestLightBlockingBlock = heightMap[columnIndex]
    if position.y > highestLightBlockingBlock {
      if newBlock.lightMaterial.opacity != 0 {
        heightMap[columnIndex] = Int(position.y)
      }
    } else if position.y == highestLightBlockingBlock && newBlock.lightMaterial.opacity == 0 {
      // If the highest block has changed and doesn't block direct sky light anymore, find the next highest valid block
      var position = position
      var foundBlock = false
      for _ in 0..<position.y {
        position.y -= 1
        let block = chunk.getBlock(at: position, acquireLock: acquireChunkLock)
        if block.lightMaterial.opacity != 0 {
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
  }
  
  /// Calculates the index of the specified column in ``heightMap``.
  private func columnIndex(_ position: BlockPosition) -> Int {
    return columnIndex(position.x, position.z)
  }
  
  /// Calculates the index of the specified column in ``heightMap``.
  private func columnIndex(_ x: Int, _ z: Int) -> Int {
    return Int(z * 16 + x)
  }
}
