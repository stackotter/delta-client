import simd

/// Builds the fluid mesh for a block.
struct FluidMeshBuilder { // TODO: Make fluid meshes look more like they do in vanilla
  /// The UVs for the top of a fluid when flowing.
  static let flowingUVs: [SIMD2<Float>] = [
    [0.75, 0.25],
    [0.25, 0.25],
    [0.25, 0.75],
    [0.75, 0.75]
  ]

  /// The UVs for the top of a fluid when still.
  static let stillUVs: [SIMD2<Float>] = [
    [1, 0],
    [0, 0],
    [0, 1],
    [1, 1]
  ]

  /// The component directions of the direction to each corner. The index of each is used as the
  /// corner's index in arrays.
  private static let cornerToDirections: [[Direction]] = [
    [.north, .east],
    [.north, .west],
    [.south, .west],
    [.south, .east]
  ]

  /// Maps directions to the indices of the corners connected to that edge.
  private static let directionToCorners: [Direction: [Int]] = [
    .north: [0, 1],
    .west: [1, 2],
    .south: [2, 3],
    .east: [3, 0]
  ]

  let position: BlockPosition
  let blockIndex: Int // Gets index as well as position to avoid duplicate calculation
  let block: Block
  let fluid: Fluid
  let chunk: Chunk
  let cullingNeighbours: Set<Direction>
  let neighbouringBlocks: [Direction: Block]
  let lightLevel: LightLevel
  let neighbouringLightLevels: [Direction: LightLevel]
  let blockTexturePalette: TexturePalette
  let world: World

  func build(into translucentMesh: inout SortableMesh) {
    // If block is surrounded by the same fluid on all sides, don't render anything.
    if neighbouringBlocks.count == 6 {
      let neighbourFluids = Set<Int?>(neighbouringBlocks.values.map { $0.fluidId })
      if neighbourFluids.count == 1 && neighbourFluids.contains(fluid.id) {
        return
      }
    }

    var tint = SIMD3<Float>(1, 1, 1)
    if block.fluidState?.fluid.identifier.name == "water" {
      guard let tintColor = chunk.biome(
        at: position.relativeToChunk,
        acquireLock: false
      )?.waterColor.floatVector else {
        // TODO: use a fallback color instead
        log.warning("Failed to get water tint")
        return
      }
      tint = tintColor
    }

    let heights = calculateHeights()
    let isFlowing = Set(heights).count > 1 // If the corners aren't all the same height, it's flowing
    let topCornerPositions = calculatePositions(heights)

    // Get textures
    guard
      let flowingTextureIndex = blockTexturePalette.textureIndex(for: fluid.flowingTexture),
      let stillTextureIndex = blockTexturePalette.textureIndex(for: fluid.stillTexture)
    else {
      log.warning("Failed to get textures for fluid")
      return
    }

    let flowingTexture = UInt16(flowingTextureIndex)
    let stillTexture = UInt16(stillTextureIndex)

    build(
      into: &translucentMesh,
      topCornerPositions: topCornerPositions,
      heights: heights,
      flowingTexture: flowingTexture,
      stillTexture: stillTexture,
      isFlowing: isFlowing,
      tint: tint
    )
  }

  func build(
    into translucentMesh: inout SortableMesh,
    topCornerPositions: [SIMD3<Float>],
    heights: [Float],
    flowingTexture: UInt16,
    stillTexture: UInt16,
    isFlowing: Bool,
    tint: SIMD3<Float>
  ) {
    let basePosition = position.relativeToChunkSection.floatVector + SIMD3<Float>(0.5, 0, 0.5)

    // Iterate through all visible faces
    for direction in Direction.allDirections where !cullingNeighbours.contains(direction) {
      let lightLevel = LightLevel.max(lightLevel, neighbouringLightLevels[direction] ?? LightLevel())
      var shade = CubeGeometry.shades[direction.rawValue]
      shade *= Float(max(lightLevel.block, lightLevel.sky)) / 15
      let tint = tint * shade

      var geometry = Geometry()
      switch direction {
        case .up:
          buildTopFace(
            into: &geometry,
            isFlowing: isFlowing,
            heights: heights,
            topCornerPositions: topCornerPositions,
            tint: tint,
            stillTexture: stillTexture,
            flowingTexture: flowingTexture
          )
        case .north, .east, .south, .west:
          buildSideFace(
            direction,
            into: &geometry,
            heights: heights,
            topCornerPositions: topCornerPositions,
            basePosition: basePosition,
            flowingTexture: flowingTexture,
            tint: tint
          )
        case .down:
          buildBottomFace(
            into: &geometry,
            basePosition: basePosition,
            topCornerPositions: topCornerPositions,
            stillTexture: stillTexture,
            tint: tint
          )
      }

      geometry.indices.append(contentsOf: CubeGeometry.faceWinding)

      translucentMesh.add(SortableMeshElement(
        geometry: geometry,
        centerPosition: position.floatVector + SIMD3<Float>(0.5, 0.5, 0.5)
      ))
    }
  }

  private func buildTopFace(
    into geometry: inout Geometry,
    isFlowing: Bool,
    heights: [Float],
    topCornerPositions: [SIMD3<Float>],
    tint: SIMD3<Float>,
    stillTexture: UInt16,
    flowingTexture: UInt16
  ) {
    var positions: [SIMD3<Float>]
    let uvs: [SIMD2<Float>]
    let texture: UInt16
    if isFlowing {
      texture = flowingTexture

      let (lowestCornersCount, lowestCornerIndex) = countLowestCorners(heights)
      uvs = generateFlowingTopFaceUVs(lowestCornersCount: lowestCornersCount)

      // Rotate corner positions so that the lowest and the opposite from the lowest are on both triangles
      positions = []
      for i in 0..<4 {
        positions.append(topCornerPositions[(i + lowestCornerIndex) & 0x3]) // & 0x3 performs mod 4
      }
    } else {
      positions = topCornerPositions
      uvs = Self.stillUVs
      texture = stillTexture
    }

    addVertices(to: &geometry, at: positions.reversed(), uvs: uvs, texture: texture, tint: tint)
  }

  private func buildSideFace(
    _ direction: Direction,
    into geometry: inout Geometry,
    heights: [Float],
    topCornerPositions: [SIMD3<Float>],
    basePosition: SIMD3<Float>,
    flowingTexture: UInt16,
    tint: SIMD3<Float>
  ) {
    // The lookup will never be nil because directionToCorners contains values for north, east, south and west
    // swiftlint:disable force_unwrapping
    let cornerIndices = Self.directionToCorners[direction]!
    // swiftlint:enable force_unwrapping

    var uvs = Self.flowingUVs
    uvs[0][1] += (1 - heights[cornerIndices[0]]) / 2
    uvs[1][1] += (1 - heights[cornerIndices[1]]) / 2
    var positions = cornerIndices.map { topCornerPositions[$0] }
    let offsets = cornerIndices.map { Self.cornerToDirections[$0] }.reversed()
    for offset in offsets {
      positions.append(basePosition + offset[0].vector/2 + offset[1].vector/2)
    }

    addVertices(to: &geometry, at: positions, uvs: uvs, texture: flowingTexture, tint: tint)
  }

  private func buildBottomFace(
    into geometry: inout Geometry,
    basePosition: SIMD3<Float>,
    topCornerPositions: [SIMD3<Float>],
    stillTexture: UInt16,
    tint: SIMD3<Float>
  ) {
    let uvs = [SIMD2<Float>](Self.stillUVs.reversed())
    var positions: [SIMD3<Float>] = []
    positions.reserveCapacity(4)
    for i in 0..<4 {
      var position = topCornerPositions[(i - 1) & 0x3] // & 0x3 is mod 4
      position.y = basePosition.y
      positions.append(position)
    }

    addVertices(to: &geometry, at: positions, uvs: uvs, texture: stillTexture, tint: tint)
  }

  /// Convert corner heights to corner positions relative to the current chunk section.
  private func calculatePositions(_ heights: [Float]) -> [SIMD3<Float>] {
    let basePosition = position.relativeToChunkSection.floatVector + SIMD3<Float>(0.5, 0, 0.5)
    var positions: [SIMD3<Float>] = []
    for (index, height) in heights.enumerated() {
      let directions = Self.cornerToDirections[index]
      var position = basePosition
      for direction in directions {
        position += direction.vector / 2
      }
      position.y += height
      positions.append(position)
    }
    return positions
  }

  /// Calculate the height of each corner of a fluid.
  private func calculateHeights() -> [Float] {
    // If under a fluid block of the same type, all corners are 1
    if neighbouringBlocks[.up]?.fluidId == block.fluidId {
      return [1, 1, 1, 1]
    }

    // Begin with all corners as the height of the current fluid
    let height = getFluidLevel(block)
    var heights = [height, height, height, height]

    // Loop through corners
    for (index, directions) in Self.cornerToDirections.enumerated() {
      if heights[index] == 1 {
        continue
      }

      // Get positions of blocks surrounding the current corner
      let zOffset = directions[0].intVector
      let xOffset = directions[1].intVector
      let positions: [BlockPosition] = [
        position + xOffset,
        position + zOffset,
        position + xOffset + zOffset
      ]

      // Get the highest fluid level around the corner
      var maxHeight = height
      for neighbourPosition in positions {
        // If any of the surrounding blocks have the fluid above them, this corner should have a height of 1
        let upperNeighbourBlock = world.getBlock(
          at: neighbourPosition + Direction.up.intVector,
          acquireLock: false
        )

        if block.fluidId == upperNeighbourBlock.fluidId {
          maxHeight = 1
          break
        }

        let neighbourBlock = world.getBlock(at: neighbourPosition, acquireLock: false)
        if block.fluidId == neighbourBlock.fluidId {
          let neighbourHeight = getFluidLevel(neighbourBlock)
          if neighbourHeight > maxHeight {
            maxHeight = neighbourHeight
          }
        }
      }
      heights[index] = maxHeight
    }

    return heights
  }

  /// Returns the height of a fluid from 0 to 1.
  /// - Parameter block: Block containing the fluid.
  /// - Returns: A height.
  private func getFluidLevel(_ block: Block) -> Float {
    if let height = block.fluidState?.height {
      return 0.9 - Float(7 - height) / 8
    } else {
      return 0.8125
    }
  }

  private func countLowestCorners(_ heights: [Float]) -> (count: Int, index: Int) {
    var lowestCornerHeight: Float = 1
    var lowestCornerIndex = 0
    var lowestCornersCount = 0 // The number of corners at the lowest height
    for (index, height) in heights.enumerated() {
      if height < lowestCornerHeight {
        lowestCornersCount = 1
        lowestCornerHeight = height
        lowestCornerIndex = index
      } else if height == lowestCornerHeight {
        lowestCornersCount += 1
      }
    }

    let previousCornerIndex = (lowestCornerIndex - 1) & 0x3
    if lowestCornersCount == 2 {
      // If there are two lowest corners next to eachother, take the first (when going anticlockwise)
      if heights[previousCornerIndex] == lowestCornerHeight {
        lowestCornerIndex = previousCornerIndex
      }
    } else if lowestCornersCount == 3 {
      // If there are three lowest corners, take the last (when going anticlockwise)
      let nextCornerIndex = (lowestCornerIndex + 1) & 0x3
      if heights[previousCornerIndex] == lowestCornerHeight && heights[nextCornerIndex] == lowestCornerHeight {
        lowestCornerIndex = nextCornerIndex
      } else if heights[nextCornerIndex] == lowestCornerHeight {
        lowestCornerIndex = (lowestCornerIndex + 2) & 0x3
      }
    }

    return (count: lowestCornersCount, index: lowestCornerIndex)
  }

  private func generateFlowingTopFaceUVs(lowestCornersCount: Int) -> [SIMD2<Float>] {
    var uvs = Self.flowingUVs

    // Rotate UVs 45 degrees if flowing diagonally
    if lowestCornersCount == 1 || lowestCornersCount == 3 {
      let uvRotation = MatrixUtil.rotationMatrix2d(lowestCornersCount == 1 ? Float.pi / 4 : 3 * Float.pi / 4)
      let center = SIMD2<Float>(repeating: 0.5)
      for (index, uv) in uvs.enumerated() {
        uvs[index] = (uv - center) * uvRotation + center
      }
    }

    return uvs
  }

  private func addVertices<Positions: Collection>(
    to geometry: inout Geometry,
    at positions: Positions,
    uvs: [SIMD2<Float>],
    texture: UInt16,
    tint: SIMD3<Float>
  ) where Positions.Element == SIMD3<Float> {
    var index = 0
    for position in positions {
      let vertex = BlockVertex(
        x: position.x,
        y: position.y,
        z: position.z,
        u: uvs[index].x,
        v: uvs[index].y,
        r: tint.x,
        g: tint.y,
        b: tint.z,
        a: 1,
        textureIndex: texture,
        isTransparent: false
      )
      geometry.vertices.append(vertex)
      index += 1
    }
  }
}
