import Foundation
import MetalKit
import simd
import SwiftUI

// TODO: update chunk section mesh builder documentation

/// Builds renderable meshes from chunk sections.
public struct ChunkSectionMeshBuilder {
  /// A lookup to quickly convert block index to block position.
  private static let indexToPosition = generateIndexLookup()
  /// A lookup tp quickly get the block indices for blocks' neighbours.
  private static let indexToNeighbourIndicesLookup = (0..<Chunk.numSections).map { generateNeighbourIndices(sectionIndex: $0) }
  
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
  
  public var stopwatch = Stopwatch(mode: .summary, name: "ChunkSectionMeshBuilder")
  
  /// Create a new mesh builder.
  ///
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
  /// - Parameter existingMesh: If present, the builder will attempt to reuse existing buffers if possible.
  /// - Returns: A mesh. `nil` if the mesh would be empty.
  public func build(reusing existingMesh: ChunkSectionMesh? = nil) -> ChunkSectionMesh? {
    // Create uniforms
    let position = SIMD3<Float>(
      Float(sectionPosition.sectionX) * 16,
      Float(sectionPosition.sectionY) * 16,
      Float(sectionPosition.sectionZ) * 16)
    let modelToWorldMatrix = MatrixUtil.translationMatrix(position)
    let uniforms = Uniforms(transformation: modelToWorldMatrix)
    
    var mesh = existingMesh ?? ChunkSectionMesh(uniforms)
    mesh.clearGeometry()
    
    // Populate mesh with geometry
    let section = chunk.sections[sectionPosition.sectionY]
    let indexToNeighbourIndices = Self.indexToNeighbourIndicesLookup[sectionPosition.sectionY]
    
    let xOffset = sectionPosition.sectionX * Chunk.Section.width
    let yOffset = sectionPosition.sectionY * Chunk.Section.height
    let zOffset = sectionPosition.sectionZ * Chunk.Section.depth
    
    if section.blockCount != 0 {
      var transparentAndOpaqueGeometry = Geometry()
      let startTime = CFAbsoluteTimeGetCurrent()
      for blockIndex in 0..<Chunk.Section.numBlocks {
        let blockId = section.getBlockId(at: blockIndex)
        if blockId != 0 {
          // TODO: benchmark whether checking for airblocks.contains(blockId) or blockId == 0 is faster overall (0 is just regular air, there are actually three types of air)
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
            indexToNeighbourIndices: indexToNeighbourIndices)
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
    at position: Position,
    atBlockIndex blockIndex: Int,
    with blockId: Int,
    transparentAndOpaqueGeometry: inout Geometry,
    translucentMesh: inout SortableMesh,
    indexToNeighbourIndices: [[(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]]
  ) {
    // Get block model
    guard let blockModel = resources.blockModelPalette.model(for: blockId, at: position) else {
      log.warning("Skipping block with no block models")
      return
    }
    
    // Get block
    guard let block = Registry.shared.blockRegistry.block(withId: blockId) else {
      log.warning("Skipping block with non-existent state id \(blockId), failed to get block information")
      return
    }
    
    // Render fluid if present
    if let fluidState = block.fluidState {
      addFluid(at: position, atBlockIndex: blockIndex, with: blockId, translucentMesh: &translucentMesh, indexToNeighbourIndices: indexToNeighbourIndices)
      if !fluidState.isWaterlogged {
        return
      }
    }
    
    // Return early if block model is empty (such as air)
    if blockModel.cullableFaces.isEmpty && blockModel.nonCullableFaces.isEmpty {
      return
    }
    
    // Get block indices of neighbouring blocks
    let neighbourIndices = indexToNeighbourIndices[blockIndex]

    // Calculate face visibility
    let culledFaces = getCullingNeighbours(at: position, blockId: blockId, neighbourIndices: neighbourIndices)
    
    // Return early if there can't possibly be any visible faces
    if blockModel.cullableFaces.count == 6 && culledFaces.count == 6 && blockModel.nonCullableFaces.count == 0 {
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
    let lightLevel = chunk.lighting.getLightLevel(at: positionRelativeToChunkSection, inSectionAt: sectionPosition.sectionY)
    let neighbourLightLevels = getNeighbourLightLevels(neighbourIndices: neighbourIndices, visibleFaces: visibleFaces)
    
    // Get tint color
    guard let biome = chunk.biome(at: position.relativeToChunk) else {
      log.warning("Block at \(position) has invalid biome with id \(chunk.biomeId(at: position))")
      return
    }
    
    let tintColor = resources.biomeColors.color(for: block, at: position, in: biome)
    
    // Create model to world transformation matrix
    let offset = block.getModelOffset(at: position)
    let modelToWorld = MatrixUtil.translationMatrix(positionRelativeToChunkSection.floatVector + offset)
    
    // Add block model to mesh
    var translucentGeometry = Geometry()
    for part in blockModel.parts {
      addModelPart(
        part,
        transformedBy: modelToWorld,
        transparentAndOpaqueGeometry: &transparentAndOpaqueGeometry,
        translucentGeometry: &translucentGeometry,
        culledFaces: culledFaces,
        lightLevel: lightLevel,
        neighbourLightLevels: neighbourLightLevels,
        tintColor: tintColor?.floatVector ?? SIMD3<Float>(1, 1, 1))
    }
    
    if !translucentGeometry.isEmpty {
      let element = SortableMeshElement(geometry: translucentGeometry, centerPosition: position.floatVector + SIMD3<Float>(0.5, 0.5, 0.5))
      translucentMesh.add(element)
    }
  }
  
  /// Adds the given block model to the mesh, positioned by the given model to world matrix.
  private func addModelPart(
    _ blockModel: BlockModelPart,
    transformedBy modelToWorld: matrix_float4x4,
    transparentAndOpaqueGeometry: inout Geometry,
    translucentGeometry: inout Geometry,
    culledFaces: Set<Direction>,
    lightLevel: LightLevel,
    neighbourLightLevels: [Direction: LightLevel],
    tintColor: SIMD3<Float>
  ) {
    for element in blockModel.elements {
      addElement(
        element,
        transformedBy: modelToWorld,
        transparentAndOpaqueGeometry: &transparentAndOpaqueGeometry,
        translucentGeometry: &translucentGeometry,
        culledFaces: culledFaces,
        lightLevel: lightLevel,
        neighbourLightLevels: neighbourLightLevels,
        tintColor: tintColor)
    }
  }
  
  /// Adds the given block model element to the mesh, positioned by the given model to world matrix.
  private func addElement(
    _ element: BlockModelElement,
    transformedBy modelToWorld: matrix_float4x4,
    transparentAndOpaqueGeometry: inout Geometry,
    translucentGeometry: inout Geometry,
    culledFaces: Set<Direction>,
    lightLevel: LightLevel,
    neighbourLightLevels: [Direction: LightLevel],
    tintColor: SIMD3<Float>
  ) {
    let vertexToWorld = element.transformation * modelToWorld
    for face in element.faces {
      if let cullFace = face.cullface, culledFaces.contains(cullFace) {
        continue
      }
      
      var faceLightLevel = neighbourLightLevels[face.actualDirection] ?? LightLevel()
      faceLightLevel = LightLevel.max(faceLightLevel, lightLevel)
      addFace(
        face,
        transformedBy: vertexToWorld,
        transparentAndOpaqueGeometry: &transparentAndOpaqueGeometry,
        translucentGeometry: &translucentGeometry,
        shouldShade: element.shade,
        lightLevel: faceLightLevel,
        tintColor: tintColor)
    }
  }
  
  /// Adds a face to some geometry.
  /// - Parameters:
  ///   - face: A face to add to the mesh.
  ///   - transformation: A transformation to apply to each vertex of the face.
  ///   - transparentAndOpaqueGeometry: The geometry to add the face to if it's not translucent.
  ///   - translucentGeometry: The geometry to add the face to if it's translucent.
  ///   - shouldShade: If `false`, the face will not be shaded based on the direction it faces. It'll still be affected by light levels.
  ///   - lightLevel: The light level to render the face at.
  ///   - tintColor: The color to tint the face as a float vector where each component has a maximum of 1. Supplying white will leave the face unaffected.
  private func addFace(
    _ face: BlockModelFace,
    transformedBy transformation: matrix_float4x4,
    transparentAndOpaqueGeometry: inout Geometry,
    translucentGeometry: inout Geometry,
    shouldShade: Bool,
    lightLevel: LightLevel,
    tintColor: SIMD3<Float>
  ) {
    let textureType = resources.blockTexturePalette.textures[face.texture].type
    if textureType == .translucent {
      addFace(
        face,
        transformedBy: transformation,
        geometry: &translucentGeometry,
        textureType: textureType,
        shouldShade: shouldShade,
        lightLevel: lightLevel,
        tintColor: tintColor)
    } else {
      addFace(
        face,
        transformedBy: transformation,
        geometry: &transparentAndOpaqueGeometry,
        textureType: textureType,
        shouldShade: shouldShade,
        lightLevel: lightLevel,
        tintColor: tintColor)
    }
  }
  
  /// Adds a face to a mesh.
  /// - Parameters:
  ///   - face: A face to add to the mesh.
  ///   - transformation: A transformation to apply to each vertex of the face.
  ///   - geometry: The geometry to add the face to.
  ///   - shouldShade: If `false`, the face will not be shaded based on the direction it faces. It'll still be affected by light levels.
  ///   - lightLevel: The light level to render the face at.
  ///   - tintColor: The color to tint the face as a float vector where each component has a maximum of 1. Supplying white will leave the face unaffected.
  private func addFace(
    _ face: BlockModelFace,
    transformedBy transformation: matrix_float4x4,
    geometry: inout Geometry,
    textureType: TextureType,
    shouldShade: Bool,
    lightLevel: LightLevel,
    tintColor: SIMD3<Float>
  ) {
    // Add face winding
    let offset = UInt32(geometry.vertices.count) // The index of the first vertex of face
    for index in CubeGeometry.faceWinding {
      geometry.indices.append(index &+ offset)
    }
    
    // swiftlint:disable force_unwrapping
    // This lookup will never be nil cause every direction is included in the static lookup table
    let faceVertexPositions = CubeGeometry.faceVertices[face.direction]!
    // swiftlint:enable force_unwrapping
    
    // Calculate shade of face
    let lightLevel = max(lightLevel.block, lightLevel.sky)
    let faceDirection = face.actualDirection.rawValue
    var shade: Float = 1.0
    if shouldShade {
      shade = CubeGeometry.shades[faceDirection]
    }
    shade *= Float(lightLevel) / 15
    
    // Calculate the tint color to apply to the face
    let tint: SIMD3<Float>
    if face.isTinted {
      tint = tintColor * shade
    } else {
      tint = SIMD3<Float>(repeating: shade)
    }
    
    let textureIndex = UInt16(face.texture)
    let isTransparent = textureType == .transparent
    
    // Add vertices to mesh
    for (uvIndex, vertexPosition) in faceVertexPositions.enumerated() {
      let position = simd_make_float3(SIMD4<Float>(vertexPosition, 1) * transformation)
      let uv = face.uvs[uvIndex]
      let vertex = BlockVertex(
        x: position.x,
        y: position.y,
        z: position.z,
        u: uv.x,
        v: uv.y,
        r: tint.x,
        g: tint.y,
        b: tint.z,
        textureIndex: textureIndex,
        isTransparent: isTransparent)
      geometry.vertices.append(vertex)
    }
  }
  
  // MARK: Fluid rendering (please refactor)
  
  // TODO: Clean this up (maybe make a FluidMeshBuilder?). This also isn't fully vanilla behaviour. But it's close enough for now.
  
  /// Adds a fluid block to the mesh.
  /// - Parameters:
  ///   - position: The position of the block in world coordinates.
  ///   - blockIndex: The index of the block in the chunk section.
  ///   - blockId: The block's id.
  ///   - translucentMesh: The mesh to add the fluid to.
  ///   - indexToNeighbourIndices: The lookup table used to find the block indices of the neighbouring blocks quickly.
  private func addFluid(
    at position: Position,
    atBlockIndex blockIndex: Int,
    with blockId: Int,
    translucentMesh: inout SortableMesh,
    indexToNeighbourIndices: [[(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]]
  ) {
    guard
      let block = Registry.shared.blockRegistry.block(withId: blockId),
      let fluid = block.fluidState?.fluid
    else {
      log.warning("Failed to get fluid block with block id \(blockId)")
      return
    }
    
    var tint = SIMD3<Float>(1, 1, 1)
    if block.fluidState?.fluid.identifier.name == "water" {
      guard let tintColor = chunk.biome(at: position.relativeToChunk)?.waterColor.floatVector else {
        // TODO: use a fallback color instead
        log.warning("Failed to get water tint")
        return
      }
      tint = tintColor
    }
    
    // Lighting
    let lightLevel = chunk.lighting.getLightLevel(atIndex: blockIndex, inSectionAt: sectionPosition.sectionY)
    let neighbourLightLevels = getNeighbourLightLevels(neighbourIndices: indexToNeighbourIndices[blockIndex], visibleFaces: [.up, .down, .north, .east, .south, .west])
    
    // UVs
    let flowingUVs: [SIMD2<Float>] = [
      [0.75, 0.25],
      [0.25, 0.25],
      [0.25, 0.75],
      [0.75, 0.75]]
    
    let stillUVs: [SIMD2<Float>] = [
      [1, 0],
      [0, 0],
      [0, 1],
      [1, 1]]
    
    let neighbouringBlockIds = getNeighbouringBlockIds(neighbourIndices: indexToNeighbourIndices[blockIndex])
    var cullingNeighbours = getCullingNeighbours(at: position.relativeToChunkSection, blockId: blockId, neighbouringBlocks: neighbouringBlockIds)
    var neighbourBlocks = [Direction: Block](minimumCapacity: 6)
    for (direction, neighbourBlockId) in neighbouringBlockIds {
      let neighbourBlock = Registry.shared.blockRegistry.block(withId: neighbourBlockId)
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
              let uvRotation = MatrixUtil.rotationMatrix2d(lowestCornersCount == 1 ? .pi / 4 : 3 * .pi / 4)
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
          let cornerIndices = Self.directionCorners[direction]!
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
  private func calculatePositions(_ blockPosition: Position, _ heights: [Float]) -> [SIMD3<Float>] {
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
  private func calculateHeights(position: Position, block: Block, neighbourBlocks: [Direction: Block]) -> [Float] {
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
      let positions: [Position] = [
        position + xOffset,
        position + zOffset,
        position + xOffset + zOffset]
      
      // Get the highest fluid level around the corner
      var maxHeight = height
      for neighbourPosition in positions {
        // If any of the surrounding blocks have the fluid above them, this corner should have a height of 1
        let upperNeighbourBlock = world.getBlock(at: neighbourPosition + Direction.up.intVector)
        if block.fluidId == upperNeighbourBlock.fluidId {
          maxHeight = 1
          break
        }
        
        let neighbourBlock = world.getBlock(at: neighbourPosition)
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
  ///
  /// - Returns: A mapping from each possible direction to a corresponding block id.
  func getNeighbouringBlockIds(neighbourIndices: [(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]) -> [(Direction, Int)] {
    // Convert a section relative index to a chunk relative index
    var neighbouringBlocks: [(Direction, Int)] = []
    neighbouringBlocks.reserveCapacity(6)
    
    for (faceDirection, neighbourChunkDirection, neighbourIndex) in neighbourIndices {
      if let direction = neighbourChunkDirection {
        let neighbourChunk = neighbourChunks.neighbour(in: direction)
        neighbouringBlocks.append((faceDirection, neighbourChunk.getBlockId(at: neighbourIndex)))
      } else {
        neighbouringBlocks.append((faceDirection, chunk.getBlockId(at: neighbourIndex)))
      }
    }
    
    return neighbouringBlocks
  }
  
  /// Returns a map from each direction to a cardinal direction and a chunk relative block index.
  ///
  /// The cardinal direction is which chunk a neighbour resides in. If the cardinal direction for
  /// a neighbour is nil then the neighbour is in the current chunk.
  ///
  /// - Parameter index: A section-relative block index
  static func getNeighbourIndices(ofBlockAt index: Int, inSection sectionIndex: Int) -> [(direction: Direction, chunkDirection: CardinalDirection?, index: Int)] {
    let indexInChunk = index &+ sectionIndex &* Chunk.Section.numBlocks
    var neighbouringIndices: [(direction: Direction, chunkDirection: CardinalDirection?, index: Int)] = []
    neighbouringIndices.reserveCapacity(6)
    
    let indexInLayer = indexInChunk % Chunk.blocksPerLayer
    if indexInLayer >= Chunk.width {
      neighbouringIndices.append((direction: .north, nil, indexInChunk &- Chunk.width))
    } else {
      neighbouringIndices.append((direction: .north, chunkDirection: .north, index: indexInChunk + Chunk.blocksPerLayer - Chunk.width))
    }
    
    if indexInLayer < Chunk.blocksPerLayer &- Chunk.width {
      neighbouringIndices.append((direction: .south, nil, indexInChunk &+ Chunk.width))
    } else {
      neighbouringIndices.append((direction: .south, chunkDirection: .south, index: indexInChunk - Chunk.blocksPerLayer + Chunk.width))
    }
    
    let indexInRow = indexInChunk % Chunk.width
    if indexInRow != Chunk.width &- 1 {
      neighbouringIndices.append((direction: .east, nil, indexInChunk &+ 1))
    } else {
      neighbouringIndices.append((direction: .east, chunkDirection: .east, index: indexInChunk &- 15))
    }
    
    if indexInRow != 0 {
      neighbouringIndices.append((direction: .west, nil, indexInChunk &- 1))
    } else {
      neighbouringIndices.append((direction: .west, chunkDirection: .west, index: indexInChunk &+ 15))
    }
    
    if indexInChunk < Chunk.numBlocks &- Chunk.blocksPerLayer {
      neighbouringIndices.append((direction: .up, nil, indexInChunk &+ Chunk.blocksPerLayer))
      
      if indexInChunk >= Chunk.blocksPerLayer {
        neighbouringIndices.append((direction: .down, nil, indexInChunk &- Chunk.blocksPerLayer))
      }
    }
    
    return neighbouringIndices
  }
  
  /// Gets the light levels of the blocks surrounding a block.
  /// - Parameters:
  ///   - neighbourIndices: The lookup table for finding the indices of neighbouring blocks.
  ///   - visibleFaces: The set of faces to get the light levels of.
  /// - Returns: A dictionary of face direction to light level for all faces in `visibleFaces`.
  func getNeighbourLightLevels(neighbourIndices: [(direction: Direction, chunkDirection: CardinalDirection?, index: Int)], visibleFaces: Set<Direction>) -> [Direction: LightLevel] {
    var lightLevels = [Direction: LightLevel](minimumCapacity: 6)
    for (direction, neighbourChunkDirection, neighbourIndex) in neighbourIndices {
      if visibleFaces.contains(direction) {
        if let chunkDirection = neighbourChunkDirection {
          lightLevels[direction] = neighbourChunks.neighbour(in: chunkDirection).lighting.getLightLevel(at: neighbourIndex)
        } else {
          lightLevels[direction] = chunk.lighting.getLightLevel(at: neighbourIndex)
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
  func getCullingNeighbours(at position: Position, blockId: Int, neighbouringBlocks: [(Direction, Int)]) -> Set<Direction> {
    var cullingNeighbours = Set<Direction>(minimumCapacity: 6)
    let blockCullsSameKind = Registry.shared.blockRegistry.selfCullingBlocks.contains(blockId)
    
    for (direction, neighbourBlockId) in neighbouringBlocks where neighbourBlockId != 0 {
      // We assume that block model variants always have the same culling faces as eachother, so no position is passed to getModel.
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
  func getCullingNeighbours(at position: Position, blockId: Int, neighbourIndices: [(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]) -> Set<Direction> {
    let neighbouringBlocks = getNeighbouringBlockIds(neighbourIndices: neighbourIndices)
    return getCullingNeighbours(at: position, blockId: blockId, neighbouringBlocks: neighbouringBlocks)
  }
  
  /// Generates a lookup table to quickly convert from section block index to block position.
  private static func generateIndexLookup() -> [Position] {
    var lookup: [Position] = []
    lookup.reserveCapacity(Chunk.Section.numBlocks)
    for y in 0..<Chunk.Section.height {
      for z in 0..<Chunk.Section.depth {
        for x in 0..<Chunk.Section.width {
          let position = Position(x: x, y: y, z: z)
          lookup.append(position)
        }
      }
    }
    return lookup
  }
  
  private static func generateNeighbourIndices(sectionIndex: Int) -> [[(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]] {
    var neighbourIndices: [[(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]] = []
    for i in 0..<Chunk.Section.numBlocks {
      neighbourIndices.append(getNeighbourIndices(ofBlockAt: i, inSection: sectionIndex))
    }
    return neighbourIndices
  }
}
