/// A 3d data structure used for flood filling chunk sections. Each 'voxel' is represented by an integer.
///
/// The graph is initialised with `true` representing voxels that cannot be seen through whatsoever and `false` representing all other voxels.
/// ``calculateConnectivity()`` figures out which faces are connected. When faces aren't connected it means that a ray cannot be created
/// that enters through one of the faces and out the other. When faces are connected it doesn't necessarily mean such a ray exists, only that it might exist.
///
/// Flood fills fill connected volumes of `false` with `true` and record which faces the fill reached. If two faces are reached by the
/// same fill, they are counted as connected.
public struct ChunkSectionVoxelGraph {
  /// The width, height and depth of the image (they're all equal to this number).
  public let dimension: Int
  /// The number of voxels per layer of the graph (``dimension`` squared).
  public let voxelsPerLayer: Int
  
  /// The initial number of voxels that weren't set to 0.
  private var initialVoxelCount: Int
  /// Stores the image's voxels. Indexed by `y * voxelsPerLayer + z * dimension + x`.
  private var voxels: [Bool]
  /// Used to efficiently set voxels values in ``voxels``. Will be invalid in copies of the graph (because it's a struct).
  private var mutableVoxelsPointer: UnsafeMutableBufferPointer<Bool>
  
  // MARK: Private methods
  
  /// Creates a new graph of the section for figuring out face connectivity.
  /// - Parameter section: Section to create graph for.
  /// - Parameter blockModelPalette: Used to determine which blocks are solid.
  public init(for section: Chunk.Section, blockModelPalette: BlockModelPalette) {
    assert(
      Chunk.Section.width == Chunk.Section.height && Chunk.Section.height == Chunk.Section.depth,
      "Attempted to create a ChunkSectionVoxelGraph from non-cubic chunk section")
    
    dimension = Chunk.Section.width
    voxelsPerLayer = dimension * dimension
    
    assert(dimension.isPowerOfTwo, "Attempted to initialise a ChunkSectionVoxelGraph with a dimension that isn't a power of two.")
    
    initialVoxelCount = 0
    voxels = []
    voxels.reserveCapacity(section.blocks.count)
    for block in section.blocks {
      let isFullyOpaque = blockModelPalette.isBlockFullyOpaque(Int(block))
      voxels.append(isFullyOpaque)
      if isFullyOpaque {
        initialVoxelCount += 1
      }
    }
    
    mutableVoxelsPointer = self.voxels.withUnsafeMutableBufferPointer { $0 }
    
    assert(
      dimension * dimension * dimension == voxels.count,
      "Attempted to initialise a ChunkSectionVoxelGraph with an invalid number of voxels for its dimension (dimension=\(dimension), voxel_count=\(voxels.count)")
  }
  
  // MARK: Public methods
  
  /// Gets information about the connectivity of the section's faces. See ``ChunkSectionVoxelGraph``.
  /// - Returns: Information about which pairs of faces are connected.
  public mutating func calculateConnectivity() -> ChunkSectionFaceConnectivity {
    if initialVoxelCount == 0 {
      return ChunkSectionFaceConnectivity.fullyConnected
    }
    
    var connectivity = ChunkSectionFaceConnectivity()
    
    // Make sure that the pointer is still valid
    mutableVoxelsPointer = voxels.withUnsafeMutableBufferPointer { $0 }
    
    let emptyVoxelCoordinates = emptyVoxelCoordinates()
    var nextEmptyVoxel = 0
    
  outerLoop:
    while true {
      var seedX: Int?
      var seedY: Int?
      var seedZ: Int?
      
      // Find the next voxel that hasn't been filled yet
      while true {
        if nextEmptyVoxel == emptyVoxelCoordinates.count {
          break outerLoop
        }
        
        let (x, y, z) = emptyVoxelCoordinates[nextEmptyVoxel]
        nextEmptyVoxel += 1
        
        if getVoxel(x: x, y: y, z: z) == false {
          seedX = x
          seedY = y
          seedZ = z
          break
        }
      }
      
      // Flood fill the section (starting at the seed voxel) and update the connectivity
      // of the section depending on which faces the fill reached.
      if let seedX = seedX, let seedY = seedY, let seedZ = seedZ {
        var group = DirectionSet()
        iterativeFloodFill(x: seedX, y: seedY, z: seedZ, group: &group)
        for i in 0..<5 {
          for j in (i+1)..<6 {
            let first = DirectionSet.directions[i]
            let second = DirectionSet.directions[j]
            
            if group.contains(first) && group.contains(second) {
              let first = ChunkSectionFace.allCases[i]
              let second = ChunkSectionFace.allCases[j]
              connectivity.setConnected(first, second)
            }
          }
        }
      } else {
        break
      }
    }
    
    return connectivity
  }
  
  /// Gets the value of the given voxel.
  ///
  /// Does not validate the position. Behaviour is undefined if the position is not inside the chunk.
  /// - Parameters:
  ///   - x: x coordinate of the voxel.
  ///   - y: y coordinate of the voxel.
  ///   - z: z coordinate of the voxel.
  /// - Returns: Current value of the voxel.
  private func getVoxel(x: Int, y: Int, z: Int) -> Bool {
    return voxels.withUnsafeBufferPointer { $0[(y &* dimension &+ z) &* dimension &+ x] }
  }
  
  /// Sets the value of the given voxel.
  /// - Parameters:
  ///   - x: x coordinate of the voxel.
  ///   - y: y coordinate of the voxel.
  ///   - z: z coordiante of the voxel.
  ///   - value: New value for the voxel.
  private mutating func setVoxel(x: Int, y: Int, z: Int, to value: Bool) {
    mutableVoxelsPointer[(y &* dimension &+ z) &* dimension &+ x] = value
  }
  
  /// Iteratively flood fills all voxels connected to the seed voxel that are set to `false`.
  /// - Parameters:
  ///   - x: x coordinate of the seed voxel.
  ///   - y: y coordinate of the seed voxel.
  ///   - z: z coordinate of the seed voxel.
  ///   - group: Stores which faces the flood fill has reached. Should be empty to start off.
  private mutating func iterativeFloodFill(x: Int, y: Int, z: Int, group: inout DirectionSet) {
    var stack: [(Int, Int, Int)] = [(x, y, z)]
    // 256 is just a rough estimate of how deep the stack might get. In reality the stack actually
    // varies from under 80 to over 20000 depending on the chunk section.
    stack.reserveCapacity(256)
    
    while let position = stack.popLast() {
      let x = position.0
      let y = position.1
      let z = position.2
      
      if isInBounds(x: x, y: y, z: z) && getVoxel(x: x, y: y, z: z) == false {
        if x == 0 {
          group.insert(.west)
        } else if x == dimension &- 1 {
          group.insert(.east)
        }
        
        if y == 0 {
          group.insert(.down)
        } else if y == dimension &- 1 {
          group.insert(.up)
        }
        
        if z == 0 {
          group.insert(.north)
        } else if z == dimension &- 1 {
          group.insert(.south)
        }
        
        setVoxel(x: x, y: y, z: z, to: true)
        
        stack.append((x &+ 1, y, z))
        stack.append((x &- 1, y, z))
        stack.append((x, y &+ 1, z))
        stack.append((x, y &- 1, z))
        stack.append((x, y, z &+ 1))
        stack.append((x, y, z &- 1))
      }
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
          if getVoxel(x: x, y: y, z: z) == false {
            coordinates.append((x, y, z))
          }
        }
      }
    }
    
    return coordinates
  }
}
