import Foundation
import MetalKit
import SwiftUI // TODO: why???
import FirebladeMath
import DeltaCore

/// Builds renderable meshes from chunk sections.
///
/// Assumes that all relevant chunks have already been locked.
public struct ChunkSectionMeshBuilder { // TODO: Bring docs up to date
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
    let position = Vec3f(
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
    if blockModel.cullableFaces == DirectionSet.all && culledFaces == DirectionSet.all && blockModel.nonCullableFaces.isEmpty {
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

      // Return early if no faces are visible
      if visibleFaces.isEmpty {
        return
      }
    }

    // Get lighting
    let positionRelativeToChunkSection = position.relativeToChunkSection
    let lightLevel = chunk.getLighting(acquireLock: false).getLightLevel(
      at: positionRelativeToChunkSection,
      inSectionAt: sectionPosition.sectionY
    )
    let neighbourLightLevels = getNeighbouringLightLevels(neighbours: neighbours, visibleFaces: visibleFaces)

    // Get tint color
    guard let biome = chunk.biome(at: position.relativeToChunk, acquireLock: false) else {
      let biomeId = chunk.biomeId(at: position, acquireLock: false).map(String.init) ?? "unknown"
      log.warning("Block at \(position) has invalid biome with id \(biomeId)")
      return
    }

    let tintColor = resources.biomeColors.color(for: block, at: position, in: biome)

    // Create model to world transformation matrix
    let offset = block.getModelOffset(at: position)
    let modelToWorld = MatrixUtil.translationMatrix(positionRelativeToChunkSection.floatVector + offset)

    // Add block model to mesh
    addBlockModel(
      blockModel,
      to: &transparentAndOpaqueGeometry,
      translucentMesh: &translucentMesh,
      position: position,
      modelToWorld: modelToWorld,
      culledFaces: culledFaces,
      lightLevel: lightLevel,
      neighbourLightLevels: neighbourLightLevels,
      tintColor: tintColor?.floatVector ?? [1, 1, 1]
    )
  }

  private func addBlockModel(
    _ model: BlockModel,
    to transparentAndOpaqueGeometry: inout Geometry,
    translucentMesh: inout SortableMesh,
    position: BlockPosition,
    modelToWorld: Mat4x4f,
    culledFaces: DirectionSet,
    lightLevel: LightLevel,
    neighbourLightLevels: [Direction: LightLevel],
    tintColor: Vec3f
  ) {
    var translucentGeometry = SortableMeshElement(centerPosition: [0, 0, 0])
    BlockMeshBuilder(
      model: model,
      position: position,
      modelToWorld: modelToWorld,
      culledFaces: culledFaces,
      lightLevel: lightLevel,
      neighbourLightLevels: neighbourLightLevels,
      tintColor: tintColor,
      blockTexturePalette: resources.blockTexturePalette
    ).build(
      into: &transparentAndOpaqueGeometry,
      translucentGeometry: &translucentGeometry
    )

    if !translucentGeometry.isEmpty {
      translucentMesh.add(translucentGeometry)
    }
  }

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

    let neighbouringBlockIds = getNeighbouringBlockIds(neighbours: indexToNeighbours[blockIndex])
    let cullingNeighbours = getCullingNeighbours(
      at: position.relativeToChunkSection,
      forFluid: fluid,
      blockId: blockId,
      neighbouringBlocks: neighbouringBlockIds
    )
    var neighbouringBlocks = [Direction: Block](minimumCapacity: 6)
    for (direction, neighbourBlockId) in neighbouringBlockIds {
      let neighbourBlock = RegistryStore.shared.blockRegistry.block(withId: neighbourBlockId)
      neighbouringBlocks[direction] = neighbourBlock
    }

    let lightLevel = chunk
      .getLighting(acquireLock: false)
      .getLightLevel(atIndex: blockIndex, inSectionAt: sectionPosition.sectionY)
    let neighbouringLightLevels = getNeighbouringLightLevels(
      neighbours: indexToNeighbours[blockIndex],
      visibleFaces: [.up, .down, .north, .east, .south, .west]
    )

    let builder = FluidMeshBuilder(
      position: position,
      blockIndex: blockIndex,
      block: block,
      fluid: fluid,
      chunk: chunk,
      cullingNeighbours: cullingNeighbours,
      neighbouringBlocks: neighbouringBlocks,
      lightLevel: lightLevel,
      neighbouringLightLevels: neighbouringLightLevels,
      blockTexturePalette: resources.blockTexturePalette,
      world: world
    )
    builder.build(into: &translucentMesh)
  }

  // MARK: Helper

  /// Gets the chunk that contains the given neighbour block.
  /// - Parameter neighbourBlock: The neighbour block.
  /// - Returns: The chunk containing the block.
  func getChunk(for neighbourBlock: BlockNeighbour) -> Chunk {
    if let direction = neighbourBlock.chunkDirection {
      return neighbourChunks.neighbour(in: direction)
    } else {
      return chunk
    }
  }

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
      let blockId = getChunk(for: neighbour).getBlockId(at: neighbour.index, acquireLock: false)
      neighbouringBlocks.append((neighbour.direction, blockId))
    }

    return neighbouringBlocks
  }

  /// Gets the light levels of the blocks surrounding a block.
  /// - Parameters:
  ///   - neighbours: The neighbours to get the light levels of.
  ///   - visibleFaces: The set of faces to get the light levels of.
  /// - Returns: A dictionary of face direction to light level for all faces in `visibleFaces`.
  func getNeighbouringLightLevels(
    neighbours: [BlockNeighbour],
    visibleFaces: DirectionSet
  ) -> [Direction: LightLevel] {
    var lightLevels = [Direction: LightLevel](minimumCapacity: 6)
    for neighbour in neighbours {
      if visibleFaces.contains(neighbour.direction) {
        let lightLevel = getChunk(for: neighbour)
          .getLighting(acquireLock: false)
          .getLightLevel(at: neighbour.index)
        lightLevels[neighbour.direction] = lightLevel
      }
    }
    return lightLevels
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
    forFluid fluid: Fluid? = nil,
    blockId: Int,
    neighbours: [BlockNeighbour]
  ) -> DirectionSet {
    let neighbouringBlocks = getNeighbouringBlockIds(neighbours: neighbours)
    return getCullingNeighbours(
      at: position,
      forFluid: fluid,
      blockId: blockId,
      neighbouringBlocks: neighbouringBlocks
    )
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
    forFluid fluid: Fluid? = nil,
    blockId: Int,
    neighbouringBlocks: [(Direction, Int)]
  ) -> DirectionSet {
    // TODO: Skip directions that the block can't be culled from if possible
    var cullingNeighbours = DirectionSet()
    let blockCullsSameKind = RegistryStore.shared.blockRegistry.selfCullingBlocks.contains(blockId)

    for (direction, neighbourBlockId) in neighbouringBlocks where neighbourBlockId != 0 {
      // We assume that block model variants always have the same culling faces as eachother, so
      // no position is passed to getModel.
      guard let blockModel = resources.blockModelPalette.model(for: neighbourBlockId, at: nil) else {
        log.debug("Skipping neighbour with no block models.")
        continue
      }

      let culledByOwnKind = blockCullsSameKind && blockId == neighbourBlockId
      if blockModel.cullingFaces.contains(direction.opposite) || culledByOwnKind {
        cullingNeighbours.insert(direction)
      } else if let fluid = fluid {
        guard let neighbourBlock = RegistryStore.shared.blockRegistry.block(withId: neighbourBlockId) else {
          continue
        }

        if neighbourBlock.fluidId == fluid.id {
          cullingNeighbours.insert(direction)
        }
      }
    }

    return cullingNeighbours
  }

  // MARK: Lookup table generation

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
      neighbours.append(BlockNeighbour.neighbours(ofBlockAt: i, inSection: sectionIndex))
    }
    return neighbours
  }
}
