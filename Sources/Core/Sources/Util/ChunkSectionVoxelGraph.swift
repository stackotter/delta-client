/// A 3d data structure used for flood filling chunk sections. Each 'voxel' is represented by an integer.
///
/// The graph is initialised with 1's representing voxels that cannot be seen through whatsoever and 0's representing all other voxels.
/// ``calculateConnectivity()`` figures out which faces are connected. When faces aren't connected it means that a ray cannot be created
/// that enters through one of the faces and out the other. When faces are connected it doesn't necessarily mean such a ray exists, only that it might exist.
///
/// Flood fills fill connected volumes of 0's with a given value and update the image's connectivity information. Each fill creates a connected group
/// of voxels that all have the same id (called the group id). The image's connectivity information stores the set of groups that are touching that face (excluding 1 and 0).
/// If two faces don't share any groups in common it is known that they aren't connected through the section.
public struct ChunkSectionVoxelGraph {
  /// The width, height and depth of the image (they're all equal to this number).
  public private(set) var dimension: Int
  /// The number of voxels per layer of the graph (``dimension`` squared).
  public private(set) var voxelsPerLayer: Int
  
  /// The initial number of voxels that weren't set to 0.
  private var initialVoxelCount: Int?
  /// Stores the image's voxels. Indexed by `y * voxelsPerLayer + z * dimension + x`.
  private var voxels: [Int]
  /// Used to efficiently set voxels values in `voxels`. Will be invalid in copies of the graph (because it's a struct).
  private var mutableVoxelsPointer: UnsafeMutableBufferPointer<Int>
  
  /// Stores which voxel groups touch each face. Populated after calling ``calculateConnectivity()``.
  /// See ``ChunkSectionVoxelGraph`` for information about groups and connectivity.
  private var connectivity: [Direction: Set<Int>] = [
    .north: [],
    .east: [],
    .south: [],
    .west: [],
    .up: [],
    .down: []]
  
  // MARK: Private methods
  
  /// Creates a new graph with the given voxel data. The voxel data should only consist of 1's and 0's.
  ///
  /// Call ``calculateConnectivity()`` to populate ``connectivity``.
  ///
  /// - Parameters:
  ///   - dimension: Width of the section.
  ///   - voxels: A simple representation of the blocks in the chunk. Completely solid blocks that can't be seen past
  ///   (e.g. dirt and cobblestone as opposed to slabs) should be `1` and all other blocks should be `0`. See ``voxels``.
  public init(dimension: Int, voxels: [Int]) {
    assert(dimension.isPowerOfTwo, "Attempted to initialise a ChunkSectionVoxelGraph with a dimension that isn't a power of two.")
    assert(dimension * dimension * dimension == voxels.count, "Attempted to initialise a ChunkSectionVoxelGraph with an invalid number of voxels for its dimension (dimension=\(dimension), voxel_count=\(voxels.count)")
    
    self.dimension = dimension
    voxelsPerLayer = dimension * dimension
    self.voxels = voxels
    mutableVoxelsPointer = self.voxels.withUnsafeMutableBufferPointer { $0 }
  }
  
  /// Creates a new graph of the section for figuring out face connectivity.
  ///
  /// - Parameter section: Section to create graph for.
  /// - Parameter blockModelPalette: Used to determine which blocks are solid.
  public init(for section: Chunk.Section, blockModelPalette: BlockModelPalette) {
    assert(Chunk.Section.width == Chunk.Section.height && Chunk.Section.height == Chunk.Section.depth, "Attempted to create a ChunkSectionVoxelGraph from non-cubic chunk section")
    
    var voxels: [Int] = []
    voxels.reserveCapacity(section.blocks.count)
    for i in 0..<section.blocks.count {
      voxels.append(blockModelPalette.fullBlocks.contains(Int(section.blocks[Int(i)])) ? 1 : 0)
    }
    self.init(dimension: Chunk.Section.width, voxels: voxels)
  }
  
  // MARK: Public methods
  
  /// Gets information about the connectivity of the section's faces through the section. See ``ChunkSectionVoxelGraph``.
  /// - Returns: Information about which faces are connected.
  public mutating func calculateConnectivity() -> [Direction: Set<Direction>] {
    mutableVoxelsPointer = voxels.withUnsafeMutableBufferPointer { $0 }
    let emptyVoxelCoordinates = emptyVoxelCoordinates()
    var nextEmptyVoxel = 0
    
    var groupId = 2
    
  outerLoop:
    while true {
      var seedX: Int? = nil
      var seedY: Int? = nil
      var seedZ: Int? = nil
      
      while true {
        if nextEmptyVoxel == emptyVoxelCoordinates.count {
          break outerLoop
        }
        
        let (x, y, z) = emptyVoxelCoordinates[nextEmptyVoxel]
        nextEmptyVoxel += 1
        
        if getVoxel(x: x, y: y, z: z) == 0 {
          seedX = x
          seedY = y
          seedZ = z
          break
        }
      }
      
      if let seedX = seedX, let seedY = seedY, let seedZ = seedZ {
        recursiveFloodFill(x: seedX, y: seedY, z: seedZ, groupId: groupId)
        groupId += 1
      } else {
        break
      }
    }
    
    // TODO: Optimise this step if it's too slow, it seems pretty inefficient
    var connectivity: [Direction: Set<Direction>] = [:]
    for (face, groups) in self.connectivity {
      var connectedFaces: Set<Direction> = []
      for (otherFace, otherGroups) in self.connectivity where otherFace != face {
        if !otherGroups.union(groups).isEmpty {
          connectedFaces.insert(otherFace)
        }
      }
      connectivity[face] = connectedFaces
    }
    return connectivity
  }
  
  /// Gets the value of the given voxel.
  ///
  /// Does not validate the position. Behaviour is undefined if the position is not inside the chunk.
  ///
  /// - Parameters:
  ///   - x: x coordinate of the voxel.
  ///   - y: y coordinate of the voxel.
  ///   - z: z coordinate of the voxel.
  /// - Returns: Current value of the voxel.
  private func getVoxel(x: Int, y: Int, z: Int) -> Int {
    return voxels.withUnsafeBufferPointer { $0[y &* voxelsPerLayer &+ z &* dimension &+ x] }
  }
  
  /// Sets the value of the given voxel and updates ``connectivity`` if the voxel is connected to the edge of the chunk.
  /// - Parameters:
  ///   - x: x coordinate of the voxel.
  ///   - y: y coordinate of the voxel.
  ///   - z: z coordiante of the voxel.
  ///   - value: New value for the voxel.
  private mutating func setVoxel(x: Int, y: Int, z: Int, to value: Int) {
    if x == 0 {
      connectivity[.west]?.insert(value)
    } else if x == dimension &- 1 {
      connectivity[.east]?.insert(value)
    }
    
    if y == 0 {
      connectivity[.down]?.insert(value)
    } else if y == dimension &- 1 {
      connectivity[.up]?.insert(value)
    }
    
    if z == 0 {
      connectivity[.north]?.insert(value)
    } else if z == dimension &- 1 {
      connectivity[.south]?.insert(value)
    }
    
    mutableVoxelsPointer[y &* voxelsPerLayer &+ z &* dimension &+ x] = value
  }
  
  /// Recursively flood fills all 0 voxels connected to the seed voxel.
  /// - Parameters:
  ///   - x: x coordinate of the seed voxel.
  ///   - y: y coordinate of the seed voxel.
  ///   - z: z coordinate of the seed voxel.
  ///   - groupId: The value to set all of the connected voxels to. Also used when updating ``connectivity``.
  private mutating func recursiveFloodFill(x: Int, y: Int, z: Int, groupId: Int) {
    if isInBounds(x: x, y: y, z: z) && getVoxel(x: x, y: y, z: z) == 0 {
      setVoxel(x: x, y: y, z: z, to: groupId)
      recursiveFloodFill(x: x &+ 1, y: y, z: z, groupId: groupId)
      recursiveFloodFill(x: x &- 1, y: y, z: z, groupId: groupId)
      recursiveFloodFill(x: x, y: y &+ 1, z: z, groupId: groupId)
      recursiveFloodFill(x: x, y: y &- 1, z: z, groupId: groupId)
      recursiveFloodFill(x: x, y: y, z: z &+ 1, groupId: groupId)
      recursiveFloodFill(x: x, y: y, z: z &- 1, groupId: groupId)
    }
  }
  
  /// Only works if ``dimension`` is a power of two.
  /// - Parameters:
  ///   - x: x coordinate of point to check.
  ///   - y: y coordinate of point to check.
  ///   - z: z coordinate of point to check.
  /// - Returns: Whether the point is inside the bounds of the image or not.
  private func isInBounds(x: Int, y: Int, z: Int) -> Bool {
    return (x | y | z) >= 0 && (x | y | z) < dimension
  }
  
  /// - Returns: The coordinates of all voxels set to 0.
  private func emptyVoxelCoordinates() -> [(Int, Int, Int)] {
    var coordinates: [(Int, Int, Int)] = Array()
    coordinates.reserveCapacity(voxels.count / 2) // TODO: determine a better initial capacity
    
    for y in 0..<dimension {
      for z in 0..<dimension {
        for x in 0..<dimension {
          if getVoxel(x: x, y: y, z: z) == 0 {
            coordinates.append((x, y, z))
          }
        }
      }
    }
    
    return coordinates
  }
}

