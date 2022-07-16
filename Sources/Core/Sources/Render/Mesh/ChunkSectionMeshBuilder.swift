import Foundation
import MetalKit
import simd
import SwiftUI



// TODO: update chunk section mesh builder documentation

/// Builds renderable meshes from chunk sections.
///
/// Assumes that all relevant chunks have already been locked.
public struct ChunkSectionMeshBuilder {
  /// A lookup to quickly convert block index to block position.
  private static let indexToPosition = generateIndexLookup()
  /// A lookup tp quickly get the block indices for blocks' neighbours.
  private static let blockNeighboursLookup = (0..<Chunk.numSections).map { generateNeighbours(sectionIndex: $0) }

  /// The world containing the chunk section to prepare.
  public var world: World
  /// The chunk containing the section to prepare.
  public var chunk: Chunk
  /// The position of the section to prepare.
  public var sectionPosition: ChunkSectionPosition
  /// The chunks surrounding ``chunk``.
  public var neighbourChunks: ChunkNeighbours

  /// The resources containing the textures and block models for the builds to use.
  private let resources: ResourcePack.Resources

  /// Creates a new mesh builder.
  ///
  /// Assumes that all chunks required to prepare this section have been locked. See ``WorldMesh/chunksRequiredToPrepare(chunkAt:)``.
  /// - Parameters:
  ///   - sectionPosition: The position of the section in the world.
  ///   - chunk: The chunk the section is in.
  ///   - world: The world the chunk is in.
  ///   - neighbourChunks: The chunks surrounding the chunk the section is in. Used for face culling on the edge of the chunk.
  ///   - resourcePack: The resource pack to use for block models.
  public init(
    forSectionAt sectionPosition: ChunkSectionPosition,
    in chunk: Chunk,
    withNeighbours neighbourChunks: ChunkNeighbours,
    world: World,
    resources: ResourcePack.Resources
  ) {
    self.world = world
    self.sectionPosition = sectionPosition
    self.chunk = chunk
    self.neighbourChunks = neighbourChunks
    self.resources = resources
  }

  /// Builds a mesh for the section at ``sectionPosition`` in ``chunk``.
  ///
  /// Assumes that the chunk has been locked already.
  /// - Parameter existingMesh: If present, the builder will attempt to reuse existing buffers if possible.
  /// - Returns: A mesh. `nil` if the mesh would be empty.
  public func build(reusing existingMesh: ChunkSectionMesh? = nil) -> ChunkSectionMesh? {
    // Create uniforms
    let position = SIMD3<Float>(
      Float(sectionPosition.sectionX) * 16,
      Float(sectionPosition.sectionY) * 16,
      Float(sectionPosition.sectionZ) * 16
    )
    let modelToWorldMatrix = MatrixUtil.translationMatrix(position)
    let uniforms = Uniforms(transformation: modelToWorldMatrix)

    var mesh = existingMesh ?? ChunkSectionMesh(uniforms)
    mesh.clearGeometry()

    // Populate mesh with geometry
    let section = chunk.getSections(acquireLock: false)[sectionPosition.sectionY]
    let indexToNeighbours = Self.blockNeighboursLookup[sectionPosition.sectionY]

    let xOffset = sectionPosition.sectionX * Chunk.Section.width
    let yOffset = sectionPosition.sectionY * Chunk.Section.height
    let zOffset = sectionPosition.sectionZ * Chunk.Section.depth

    if section.blockCount != 0 {
      var transparentAndOpaqueGeometry = Geometry()
      let startTime = CFAbsoluteTimeGetCurrent()
      for blockIndex in 0..<Chunk.Section.numBlocks {
        let blockId = section.getBlockId(at: blockIndex)
        if blockId != 0 {
          var position = Self.indexToPosition[blockIndex]
          position.x += xOffset
          position.y += yOffset
          position.z += zOffset
          addBlock(
            at: position,
            atBlockIndex: blockIndex,
            with: blockId,
            transparentAndOpaqueGeometry: &transparentAndOpaqueGeometry,
            translucentMesh: &mesh.translucentMesh,
            indexToNeighbours: indexToNeighbours,
            containsFluids: &mesh.containsFluids
          )
        }
      }
      let elapsed = CFAbsoluteTimeGetCurrent() - startTime
      log.trace("Prepared mesh for Chunk.Section at \(sectionPosition) in \(elapsed) seconds")
      mesh.transparentAndOpaqueMesh.vertices = transparentAndOpaqueGeometry.vertices
      mesh.transparentAndOpaqueMesh.indices = transparentAndOpaqueGeometry.indices
    }

    if mesh.isEmpty {
      return nil
    }

    return mesh
  }

  // MARK: Block mesh building

  /// Adds a block to the mesh.
  private func addBlock(
    at position: BlockPosition,
    atBlockIndex blockIndex: Int,
    with blockId: Int,
    transparentAndOpaqueGeometry: inout Geometry,
    translucentMesh: inout SortableMesh,
    indexToNeighbours: [[BlockNeighbour]],
    containsFluids: inout Bool
  ) {
    // Get block model
    guard let blockModel = resources.blockModelPalette.model(for: blockId, at: position) else {
      log.warning("Skipping block with no block models")
      return
    }

    // Get block
    guard let block = RegistryStore.shared.blockRegistry.block(withId: blockId) else {
      log.warning("Skipping block with non-existent state id \(blockId), failed to get block information")
      return
    }

    // Render fluid if present
    if let fluidState = block.fluidState {
      containsFluids = true
      addFluid(
        at: position,
        atBlockIndex: blockIndex,
        with: blockId,
        translucentMesh: &translucentMesh,
        indexToNeighbours: indexToNeighbours
      )
      if !fluidState.isWaterlogged {
        return
      }
    }

    // Return early if block model is empty (such as air)
    if blockModel.cullableFaces.isEmpty && blockModel.nonCullableFaces.isEmpty {
      return
    }

    // Get block indices of neighbouring blocks
    let neighbours = indexToNeighbours[blockIndex]

    // Calculate face visibility
    let culledFaces = getCullingNeighbours(at: position, blockId: blockId, neighbours: neighbours)

    // Return early if there can't possibly be any visible faces
    if blockModel.cullableFaces.count == 6 && culledFaces.count == 6 && blockModel.nonCullableFaces.isEmpty {
      return
    }

    // Find the cullable faces which are visible
    var visibleFaces = blockModel.cullableFaces.subtracting(culledFaces)

    // Return early if there are no always visible faces and no non-culled faces
    if blockModel.nonCullableFaces.isEmpty && visibleFaces.isEmpty {
      return
    }

    // Add non cullable faces to the visible faces set (they are always rendered)
    if !blockModel.nonCullableFaces.isEmpty {
      visibleFaces = visibleFaces.union(blockModel.nonCullableFaces)
    }

    // Return early if no faces are visible
    if visibleFaces.isEmpty {
      return
    }

    // Get lighting
    let positionRelativeToChunkSection = position.relativeToChunkSection
    let lightLevel = chunk.getLighting(acquireLock: false).getLightLevel(
      at: positionRelativeToChunkSection,
      inSectionAt: sectionPosition.sectionY
    )
    let neighbourLightLevels = getNeighbourLightLevels(neighbours: neighbours, visibleFaces: visibleFaces)

    // Get tint color
    guard let biome = chunk.biome(at: position.relativeToChunk, acquireLock: false) else {
      log.warning("Block at \(position) has invalid biome with id \(chunk.biomeId(at: position, acquireLock: false))")
      return
    }

    let tintColor = resources.biomeColors.color(for: block, at: position, in: biome)

    // Create model to world transformation matrix
    let offset = block.getModelOffset(at: position)
    let modelToWorld = MatrixUtil.translationMatrix(positionRelativeToChunkSection.floatVector + offset)

    // Add block model to mesh
    var translucentGeometry: [(size: Float, geometry: Geometry)] = []
    addBlockModel(
      blockModel,
      transformedBy: modelToWorld,
      transparentAndOpaqueGeometry: &transparentAndOpaqueGeometry,
      translucentGeometry: &translucentGeometry,
      culledFaces: culledFaces,
      lightLevel: lightLevel,
      neighbourLightLevels: neighbourLightLevels,
      tintColor: tintColor?.floatVector ?? SIMD3<Float>(1, 1, 1)
    )

    if !translucentGeometry.isEmpty {
      // Sort the geometry assuming that smaller translucent elements are always inside of bigger
      // elements in the same block (e.g. honey block, slime block). The geometry is then combined
      // into a single element to add to the final mesh to reduce sorting calculations while
      // rendering.
      translucentGeometry.sort { first, second in
        return second.size > first.size
      }

      var vertexCount = 0
      var indexCount = 0
      for (_, geometry) in translucentGeometry {
        vertexCount += geometry.vertices.count
        indexCount += geometry.indices.count
      }

      var vertices: [BlockVertex] = []
      var indices: [UInt32] = []
      vertices.reserveCapacity(vertexCount)
      indices.reserveCapacity(indexCount)

      for (_, geometry) in translucentGeometry {
        let startingIndex = UInt32(vertices.count)
        vertices.append(contentsOf: geometry.vertices)
        indices.append(contentsOf: geometry.indices.map { $0 + startingIndex })
      }

      let geometry = Geometry(vertices: vertices, indices: indices)
      translucentMesh.add(SortableMeshElement(
        geometry: geometry,
        centerPosition: position.floatVector + SIMD3<Float>(0.5, 0.5, 0.5)
      ))
    }
  }

  /// Adds the given block model to the mesh, positioned by the given model to world matrix.
  private func addBlockModel(
    _ model: BlockModel,
    transformedBy modelToWorld: matrix_float4x4,
    transparentAndOpaqueGeometry: inout Geometry,
    translucentGeometry: inout [(size: Float, geometry: Geometry)],
    culledFaces: Set<Direction>,
    lightLevel: LightLevel,
    neighbourLightLevels: [Direction: LightLevel],
    tintColor: SIMD3<Float>
  ) {
    let builder = BlockMeshBuilder(
      model: model,
      modelToWorld: modelToWorld,
      culledFaces: culledFaces,
      lightLevel: lightLevel,
      neighbourLightLevels: neighbourLightLevels,
      tintColor: tintColor,
      blockTexturePalette: resources.blockTexturePalette
    )

    builder.build(
      into: &transparentAndOpaqueGeometry,
      translucentGeometry: &translucentGeometry
    )
  }

  // MARK: Fluid rendering (please refactor)

  // TODO: Clean this up (maybe make a FluidMeshBuilder?). This also isn't fully vanilla behaviour. But it's close enough for now.

  /// Adds a fluid block to the mesh.
  /// - Parameters:
  ///   - position: The position of the block in world coordinates.
  ///   - blockIndex: The index of the block in the chunk section.
  ///   - blockId: The block's id.
  ///   - translucentMesh: The mesh to add the fluid to.
  ///   - indexToNeighbours: The lookup table used to find the neighbours of a block quickly.
  private func addFluid(
    at position: BlockPosition,
    atBlockIndex blockIndex: Int,
    with blockId: Int,
    translucentMesh: inout SortableMesh,
    indexToNeighbours: [[BlockNeighbour]]
  ) {
    guard
      let block = RegistryStore.shared.blockRegistry.block(withId: blockId),
      let fluid = block.fluidState?.fluid
    else {
      log.warning("Failed to get fluid block with block id \(blockId)")
      return
    }

    var tint = SIMD3<Float>(1, 1, 1)
    if block.fluidState?.fluid.identifier.name == "water" {
      guard let tintColor = chunk.biome(at: position.relativeToChunk, acquireLock: false)?.waterColor.floatVector else {
        // TODO: use a fallback color instead
        log.warning("Failed to get water tint")
        return
      }
      tint = tintColor
    }

    // Lighting
    let lightLevel = chunk.getLighting(acquireLock: false).getLightLevel(atIndex: blockIndex, inSectionAt: sectionPosition.sectionY)
    let neighbourLightLevels = getNeighbourLightLevels(
      neighbours: indexToNeighbours[blockIndex],
      visibleFaces: [.up, .down, .north, .east, .south, .west]
    )

    // UVs
    let flowingUVs: [SIMD2<Float>] = [
      [0.75, 0.25],
      [0.25, 0.25],
      [0.25, 0.75],
      [0.75, 0.75]
    ]

    let stillUVs: [SIMD2<Float>] = [
      [1, 0],
      [0, 0],
      [0, 1],
      [1, 1]
    ]

    let neighbouringBlockIds = getNeighbouringBlockIds(neighbours: indexToNeighbours[blockIndex])
    var cullingNeighbours = getCullingNeighbours(
      at: position.relativeToChunkSection,
      blockId: blockId,
      neighbouringBlocks: neighbouringBlockIds
    )
    var neighbourBlocks = [Direction: Block](minimumCapacity: 6)
    for (direction, neighbourBlockId) in neighbouringBlockIds {
      let neighbourBlock = RegistryStore.shared.blockRegistry.block(withId: neighbourBlockId)
      neighbourBlocks[direction] = neighbourBlock
      if neighbourBlock?.fluidId == fluid.id {
        cullingNeighbours.insert(direction)
      }
    }

    // If block is surrounded by the same fluid on all sides, don't render anything.
    if neighbourBlocks.count == 6 {
      let neighbourFluids = Set<Int?>(neighbourBlocks.values.map { $0.fluidId })
      if neighbourFluids.count == 1 && neighbourFluids.contains(fluid.id) {
        log.trace("Fluid surrounded by same fluid, no need to render it")
        return
      }
    }

    let heights = calculateHeights(position: position, block: block, neighbourBlocks: neighbourBlocks)
    let isFlowing = Set(heights).count > 1
    let topCornerPositions = calculatePositions(position, heights)

    // Get textures
    guard
      let flowingTextureIndex = resources.blockTexturePalette.textureIndex(for: fluid.flowingTexture),
      let stillTextureIndex = resources.blockTexturePalette.textureIndex(for: fluid.stillTexture)
    else {
      log.warning("Failed to get textures for fluid")
      return
    }

    let flowingTexture = UInt16(flowingTextureIndex)
    let stillTexture = UInt16(stillTextureIndex)

    // Create faces
    let basePosition = position.relativeToChunkSection.floatVector + SIMD3<Float>(0.5, 0, 0.5)
    for direction in Direction.allDirections where !cullingNeighbours.contains(direction) {
      let lightLevel = LightLevel.max(lightLevel, neighbourLightLevels[direction] ?? LightLevel())
      var shade = CubeGeometry.shades[direction.rawValue]
      shade *= Float(max(lightLevel.block, lightLevel.sky)) / 15
      let tint = tint * shade

      var geometry = Geometry()
      switch direction {
        case .up:
          var positions: [SIMD3<Float>]
          var uvs: [SIMD2<Float>]
          var texture: UInt16
          if isFlowing {
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

            texture = flowingTexture
            uvs = flowingUVs

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

            // Rotate UVs 45 degrees if necessary
            if lowestCornersCount == 1 || lowestCornersCount == 3 {
              let uvRotation = MatrixUtil.rotationMatrix2d(lowestCornersCount == 1 ? Float.pi / 4 : 3 * Float.pi / 4)
              let center = SIMD2<Float>(repeating: 0.5)
              for (index, uv) in uvs.enumerated() {
                uvs[index] = (uv - center) * uvRotation + center
              }
            }

            // Rotate corner positions so that the lowest and the opposite from the lowest are on both triangles
            positions = []
            for i in 0..<4 {
              positions.append(topCornerPositions[(i + lowestCornerIndex) & 0x3]) // & 0x3 performs mod 4
            }
          } else {
            positions = topCornerPositions
            uvs = stillUVs
            texture = stillTexture
          }

          for (index, position) in positions.reversed().enumerated() {
            let vertex = BlockVertex(
              x: position.x,
              y: position.y,
              z: position.z,
              u: uvs[index].x,
              v: uvs[index].y,
              r: tint.x,
              g: tint.y,
              b: tint.z,
              textureIndex: texture,
              isTransparent: false)
            geometry.vertices.append(vertex)
          }

          geometry.indices.append(contentsOf: CubeGeometry.faceWinding)
        case .north, .east, .south, .west:
          // The lookup will never be nil because directionCorners contains values for north, east, south and west
          // swiftlint:disable force_unwrapping
          let cornerIndices = Self.directionCorners[direction]!
          // swiftlint:enable force_unwrapping

          var uvs = flowingUVs
          uvs[0][1] += (1 - heights[cornerIndices[0]]) / 2
          uvs[1][1] += (1 - heights[cornerIndices[1]]) / 2
          var positions = cornerIndices.map { topCornerPositions[$0] }
          let offsets = cornerIndices.map { Self.cornerDirections[$0] }.reversed()
          for offset in offsets {
            positions.append(basePosition + offset[0].vector/2 + offset[1].vector/2)
          }

          for (index, position) in positions.enumerated() {
            let vertex = BlockVertex(
              x: position.x,
              y: position.y,
              z: position.z,
              u: uvs[index].x,
              v: uvs[index].y,
              r: tint.x,
              g: tint.y,
              b: tint.z,
              textureIndex: flowingTexture,
              isTransparent: false)
            geometry.vertices.append(vertex)
          }

          geometry.indices.append(contentsOf: CubeGeometry.faceWinding)
        case .down:
          let uvs = [SIMD2<Float>](stillUVs.reversed())
          for i in 0..<4 {
            var position = topCornerPositions[(i - 1) & 0x3] // & 0x3 is mod 4
            position.y = basePosition.y
            let vertex = BlockVertex(
              x: position.x,
              y: position.y,
              z: position.z,
              u: uvs[i].x,
              v: uvs[i].y,
              r: tint.x,
              g: tint.y,
              b: tint.z,
              textureIndex: stillTexture,
              isTransparent: false)
            geometry.vertices.append(vertex)
          }

          geometry.indices.append(contentsOf: CubeGeometry.faceWinding)
      }

      translucentMesh.add(SortableMeshElement(
        geometry: geometry,
        centerPosition: position.floatVector + SIMD3<Float>(0.5, 0.5, 0.5)))
    }
  }

  /// The component directions of the direction to each corner. The index of each is used as the corner's 'index' in arrays.
  private static let cornerDirections: [[Direction]] = [
    [.north, .east],
    [.north, .west],
    [.south, .west],
    [.south, .east]]

  /// Maps directions to the indices of the corners connected to that edge.
  private static let directionCorners: [Direction: [Int]] = [
    .north: [0, 1],
    .west: [1, 2],
    .south: [2, 3],
    .east: [3, 0]]

  /// Convert corner heights to corner positions relative to the current chunk section.
  private func calculatePositions(_ blockPosition: BlockPosition, _ heights: [Float]) -> [SIMD3<Float>] {
    let basePosition = blockPosition.relativeToChunkSection.floatVector + SIMD3<Float>(0.5, 0, 0.5)
    var positions: [SIMD3<Float>] = []
    for (index, height) in heights.enumerated() {
      let directions = Self.cornerDirections[index]
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
  private func calculateHeights(position: BlockPosition, block: Block, neighbourBlocks: [Direction: Block]) -> [Float] {
    // If under a fluid block of the same type, all corners are 1
    if neighbourBlocks[.up]?.fluidId == block.fluidId {
      return [1, 1, 1, 1]
    }

    // Begin with all corners as the height of the current fluid
    let height = getFluidLevel(block)
    var heights = [height, height, height, height]

    // Loop through corners
    for (index, directions) in Self.cornerDirections.enumerated() {
      if heights[index] == 1 {
        continue
      }

      // Get positions of blocks surrounding the current corner
      let zOffset = directions[0].intVector
      let xOffset = directions[1].intVector
      let positions: [BlockPosition] = [
        position + xOffset,
        position + zOffset,
        position + xOffset + zOffset]

      // Get the highest fluid level around the corner
      var maxHeight = height
      for neighbourPosition in positions {
        // If any of the surrounding blocks have the fluid above them, this corner should have a height of 1
        let upperNeighbourBlock = world.getBlock(at: neighbourPosition + Direction.up.intVector, acquireLock: false)
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

  // MARK: Helper

  /// Gets the block id of each block neighbouring a block using the given neighbour indices.
  ///
  /// Blocks in neighbouring chunks are also included. Neighbours in cardinal directions will
  /// always be returned. If the block at `sectionIndex` is at y-level 0 or 255 the down or up neighbours
  /// will be omitted respectively (as there will be none). Otherwise, all neighbours are included.
  /// - Returns: A mapping from each possible direction to a corresponding block id.
  func getNeighbouringBlockIds(neighbours: [BlockNeighbour]) -> [(Direction, Int)] {
    // Convert a section relative index to a chunk relative index
    var neighbouringBlocks: [(Direction, Int)] = []
    neighbouringBlocks.reserveCapacity(6)

    for neighbour in neighbours {
      if let direction = neighbour.chunkDirection {
        let neighbourChunk = neighbourChunks.neighbour(in: direction)
        neighbouringBlocks.append((neighbour.direction, neighbourChunk.getBlockId(at: neighbour.index, acquireLock: false)))
      } else {
        neighbouringBlocks.append((neighbour.direction, chunk.getBlockId(at: neighbour.index, acquireLock: false)))
      }
    }

    return neighbouringBlocks
  }

  /// Returns a map from each direction to a cardinal direction and a chunk relative block index.
  ///
  /// The cardinal direction is which chunk a neighbour resides in. If the cardinal direction for
  /// a neighbour is nil then the neighbour is in the current chunk.
  /// - Parameter index: A section-relative block index
  static func getNeighbours(ofBlockAt index: Int, inSection sectionIndex: Int) -> [BlockNeighbour] {
    let indexInChunk = index &+ sectionIndex &* Chunk.Section.numBlocks
    var neighbours: [BlockNeighbour] = []
    neighbours.reserveCapacity(6)

    let indexInLayer = indexInChunk % Chunk.blocksPerLayer
    if indexInLayer >= Chunk.width {
      neighbours.append(BlockNeighbour(direction: .north, chunkDirection: nil, index: indexInChunk &- Chunk.width))
    } else {
      neighbours.append(BlockNeighbour(direction: .north, chunkDirection: .north, index: indexInChunk + Chunk.blocksPerLayer - Chunk.width))
    }

    if indexInLayer < Chunk.blocksPerLayer &- Chunk.width {
      neighbours.append(BlockNeighbour(direction: .south, chunkDirection: nil, index: indexInChunk &+ Chunk.width))
    } else {
      neighbours.append(BlockNeighbour(direction: .south, chunkDirection: .south, index: indexInChunk - Chunk.blocksPerLayer + Chunk.width))
    }

    let indexInRow = indexInChunk % Chunk.width
    if indexInRow != Chunk.width &- 1 {
      neighbours.append(BlockNeighbour(direction: .east, chunkDirection: nil, index: indexInChunk &+ 1))
    } else {
      neighbours.append(BlockNeighbour(direction: .east, chunkDirection: .east, index: indexInChunk &- 15))
    }

    if indexInRow != 0 {
      neighbours.append(BlockNeighbour(direction: .west, chunkDirection: nil, index: indexInChunk &- 1))
    } else {
      neighbours.append(BlockNeighbour(direction: .west, chunkDirection: .west, index: indexInChunk &+ 15))
    }

    if indexInChunk < Chunk.numBlocks &- Chunk.blocksPerLayer {
      neighbours.append(BlockNeighbour(direction: .up, chunkDirection: nil, index: indexInChunk &+ Chunk.blocksPerLayer))

      if indexInChunk >= Chunk.blocksPerLayer {
        neighbours.append(BlockNeighbour(direction: .down, chunkDirection: nil, index: indexInChunk &- Chunk.blocksPerLayer))
      }
    }

    return neighbours
  }

  /// Gets the light levels of the blocks surrounding a block.
  /// - Parameters:
  ///   - neighbours: The neighbours to get the light levels of.
  ///   - visibleFaces: The set of faces to get the light levels of.
  /// - Returns: A dictionary of face direction to light level for all faces in `visibleFaces`.
  func getNeighbourLightLevels(neighbours: [BlockNeighbour], visibleFaces: Set<Direction>) -> [Direction: LightLevel] {
    var lightLevels = [Direction: LightLevel](minimumCapacity: 6)
    for neighbour in neighbours {
      if visibleFaces.contains(neighbour.direction) {
        if let chunkDirection = neighbour.chunkDirection {
          lightLevels[neighbour.direction] = neighbourChunks.neighbour(in: chunkDirection).getLighting(acquireLock: false).getLightLevel(at: neighbour.index)
        } else {
          lightLevels[neighbour.direction] = chunk.getLighting(acquireLock: false).getLightLevel(at: neighbour.index)
        }
      }
    }
    return lightLevels
  }

  /// Gets an array of the direction of all blocks neighbouring the block at `position` that have
  /// full faces facing the block at `position`.
  /// - Parameters:
  ///   - position: The position of the block relative to `sectionPosition`.
  ///   - blockId: The id of the block at the given position.
  ///   - neighbouringBlocks: The block ids of neighbouring blocks.
  /// - Returns: The set of directions of neighbours that can possibly cull a face.
  func getCullingNeighbours(
    at position: BlockPosition,
    blockId: Int,
    neighbouringBlocks: [(Direction, Int)]
  ) -> Set<Direction> {
    var cullingNeighbours = Set<Direction>(minimumCapacity: 6)
    let blockCullsSameKind = RegistryStore.shared.blockRegistry.selfCullingBlocks.contains(blockId)

    for (direction, neighbourBlockId) in neighbouringBlocks where neighbourBlockId != 0 {
      // We assume that block model variants always have the same culling faces as eachother, so
      // no position is passed to getModel.
      guard let blockModel = resources.blockModelPalette.model(for: neighbourBlockId, at: nil) else {
        log.debug("Skipping neighbour with no block models.")
        continue
      }

      if blockModel.cullingFaces.contains(direction.opposite) || (blockCullsSameKind && blockId == neighbourBlockId) {
        cullingNeighbours.insert(direction)
      }
    }

    return cullingNeighbours
  }

  /// Gets an array of the direction of all blocks neighbouring the block at `position` that have
  /// full faces facing the block at `position`.
  /// - Parameters:
  ///   - position: The position of the block relative to the section.
  ///   - blockId: The id of the block at the given position.
  ///   - neighbourIndices: The neighbour indices lookup table to use.
  /// - Returns: The set of directions of neighbours that can possibly cull a face.
  func getCullingNeighbours(
    at position: BlockPosition,
    blockId: Int,
    neighbours: [BlockNeighbour]
  ) -> Set<Direction> {
    let neighbouringBlocks = getNeighbouringBlockIds(neighbours: neighbours)
    return getCullingNeighbours(at: position, blockId: blockId, neighbouringBlocks: neighbouringBlocks)
  }

  /// Generates a lookup table to quickly convert from section block index to block position.
  private static func generateIndexLookup() -> [BlockPosition] {
    var lookup: [BlockPosition] = []
    lookup.reserveCapacity(Chunk.Section.numBlocks)
    for y in 0..<Chunk.Section.height {
      for z in 0..<Chunk.Section.depth {
        for x in 0..<Chunk.Section.width {
          let position = BlockPosition(x: x, y: y, z: z)
          lookup.append(position)
        }
      }
    }
    return lookup
  }

  private static func generateNeighbours(sectionIndex: Int) -> [[BlockNeighbour]] {
    var neighbours: [[BlockNeighbour]] = []
    for i in 0..<Chunk.Section.numBlocks {
      neighbours.append(getNeighbours(ofBlockAt: i, inSection: sectionIndex))
    }
    return neighbours
  }
}
