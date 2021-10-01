import Foundation
import MetalKit
import simd

/// Builds renderable meshes from chunk sections.
public struct ChunkSectionMeshBuilder {
  /// A lookup to quickly convert block index to block position.
  private static let indexToPosition = generateIndexLookup()
  /// A lookup tp quickly get the block indices for blocks' neighbours.
  private static let indexToNeighbourIndicesLookup = (0..<Chunk.numSections).map { generateNeighbourIndices(sectionIndex: $0) }
  
  /// The chunk containing the section to prepare.
  public var chunk: Chunk
  /// The position of the section to prepare.
  public var sectionPosition: ChunkSectionPosition
  /// The chunks surrounding ``chunk``.
  public var neighbourChunks: [CardinalDirection: Chunk]
  
  /// The resources containing the textures and block models for the builds to use.
  private let resources: ResourcePack.Resources
  
  var stopwatch = Stopwatch(mode: .summary, name: "ChunkSectionMeshBuilder")
  
  /// Create a new mesh builder.
  ///
  /// - Parameters:
  ///   - sectionPosition: The position of the section in the world.
  ///   - chunk: The chunk the section is in.
  ///   - neighbourChunks: The chunks surrounding the chunk the section is in. Used for face culling on the edge of the chunk.
  ///   - resourcePack: The resource pack to use for block models.
  public init(
    forSectionAt sectionPosition: ChunkSectionPosition,
    in chunk: Chunk,
    withNeighbours neighbourChunks: [CardinalDirection: Chunk],
    resources: ResourcePack.Resources
  ) {
    self.sectionPosition = sectionPosition
    self.chunk = chunk
    self.neighbourChunks = neighbourChunks
    self.resources = resources
  }
  
  /// Builds a mesh for the section at ``sectionPosition`` in ``chunk``.
  /// - Returns: A mesh. `nil` if the mesh would be empty.
  public func build() -> Mesh? {
    var mesh = Mesh()
    
    // add the section's blocks to the mesh
    let section = chunk.sections[sectionPosition.sectionY]
    let indexToNeighbourIndices = Self.indexToNeighbourIndicesLookup[sectionPosition.sectionY]
    
    let xOffset = sectionPosition.sectionX * Chunk.Section.width
    let yOffset = sectionPosition.sectionY * Chunk.Section.height
    let zOffset = sectionPosition.sectionZ * Chunk.Section.depth
    
    if section.blockCount != 0 {
      let startTime = CFAbsoluteTimeGetCurrent()
      for blockIndex in 0..<Chunk.Section.numBlocks {
        let state = section.getBlockState(at: blockIndex)
        if state != 0 {
          var position = Self.indexToPosition[blockIndex]
          position.x += xOffset
          position.y += yOffset
          position.z += zOffset
          addBlock(at: position, atBlockIndex: blockIndex, with: state, to: &mesh, indexToNeighbourIndices: indexToNeighbourIndices)
        }
      }
      let elapsed = CFAbsoluteTimeGetCurrent() - startTime
      log.trace("Prepared mesh for Chunk.Section at \(sectionPosition) in \(elapsed) seconds")
    }
    
    // Return early if the mesh contains no geometry.
    if mesh.isEmpty {
      return nil
    }
    
    // Create uniforms
    let position = simd_float3(
      Float(sectionPosition.sectionX) * 16,
      Float(sectionPosition.sectionY) * 16,
      Float(sectionPosition.sectionZ) * 16)
    let modelToWorldMatrix = MatrixUtil.translationMatrix(position)
    let uniforms = Uniforms(transformation: modelToWorldMatrix)
    mesh.uniforms = uniforms
    
    return mesh
  }
  
  /// Adds a block to the mesh.
  private func addBlock(
    at position: Position,
    atBlockIndex blockIndex: Int,
    with state: UInt16,
    to mesh: inout Mesh,
    indexToNeighbourIndices: [[(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]]
  ) {
    // Get block model
    let state = Int(state)
    guard let blockModel = resources.blockModelPalette.model(for: state, at: position) else {
      log.warning("Skipping block with no block models")
      return
    }
    
    // Return early if block model is empty (such as air)
    if blockModel.cullableFaces.isEmpty && blockModel.nonCullableFaces.isEmpty {
      return
    }
    
    // Get block indices of neighbouring blocks
    let neighbourIndices = indexToNeighbourIndices[blockIndex]

    // Calculate face visibility
    let culledFaces = getCullingNeighbours(at: position, neighbourIndices: neighbourIndices)
    
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
    
    // Get block
    guard let block = Registry.blockRegistry.block(forStateWithId: state) else {
      log.warning("Skipping block with non-existent id \(state)")
      return
    }
    
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
    for part in blockModel.parts {
      addModelPart(
        part,
        transformedBy: modelToWorld,
        to: &mesh,
        culledFaces: culledFaces,
        lightLevel: lightLevel,
        neighbourLightLevels: neighbourLightLevels,
        tintColor: tintColor?.floatVector ?? SIMD3<Float>(1, 1, 1))
    }
  }
  
  /// Adds the given block model to the mesh, positioned by the given model to world matrix.
  private func addModelPart(
    _ blockModel: BlockModelPart,
    transformedBy modelToWorld: matrix_float4x4,
    to mesh: inout Mesh,
    culledFaces: Set<Direction>,
    lightLevel: LightLevel,
    neighbourLightLevels: [Direction: LightLevel],
    tintColor: SIMD3<Float>
  ) {
    for element in blockModel.elements {
      addElement(
        element,
        transformedBy: modelToWorld,
        to: &mesh,
        culledFaces: culledFaces,
        lightLevel: lightLevel,
        neighbourLightLevels: neighbourLightLevels,
        tintColor: tintColor)
    }
  }
  
  /// Adds the given blok model element to the mesh, positioned by the given model to world matrix.
  private func addElement(
    _ element: BlockModelElement,
    transformedBy modelToWorld: matrix_float4x4,
    to mesh: inout Mesh,
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
        to: &mesh,
        shouldShade: element.shade,
        lightLevel: faceLightLevel,
        tintColor: tintColor)
    }
  }
  
  /// Adds a face to a mesh.
  /// - Parameters:
  ///   - face: A face to add to the mesh.
  ///   - transformation: A transformation to apply to each vertex of the face.
  ///   - mesh: A mesh to add the face to.
  ///   - shouldShade: If `false`, the face will not be shaded based on the direction it faces. It'll still be affected by light levels.
  ///   - lightLevel: The light level to render the face at.
  ///   - tintColor: The color to tint the face as a float vector where each component has a maximum of 1. Supplying white will leave the face unaffected.
  private func addFace(
    _ face: BlockModelFace,
    transformedBy transformation: matrix_float4x4,
    to mesh: inout Mesh,
    shouldShade: Bool,
    lightLevel: LightLevel,
    tintColor: SIMD3<Float>
  ) {
    // Add face winding
    let offset = UInt32(mesh.vertices.count) // The index of the first vertex of face
    for index in CubeGeometry.faceWinding {
      mesh.indices.append(index &+ offset)
    }
    
    // swiftlint:disable force_unwrapping
    // This lookup will never be nil cause every direction is included in the static lookup table
    let faceVertexPositions = CubeGeometry.faceVertices[face.direction]!
    // swiftlint:enable force_unwrapping
    
    let isTextureTransparent = resources.blockTexturePalette.textures[face.texture].type == .transparent
    
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
    
    // Add vertices to mesh
    for (uvIndex, vertexPosition) in faceVertexPositions.enumerated() {
      let position = simd_make_float3(simd_float4(vertexPosition, 1) * transformation)
      let uv = face.uvs[uvIndex]
      let vertex = Vertex(
        x: position.x,
        y: position.y,
        z: position.z,
        u: uv.x,
        v: uv.y,
        r: tint.x,
        g: tint.y,
        b: tint.z,
        textureIndex: textureIndex,
        isTransparent: isTextureTransparent)
      mesh.vertices.append(vertex)
    }
  }
  
  /// Gets the block state of each block neighbouring the block at `sectionIndex`.
  ///
  /// Blocks in neighbouring chunks are also included. Neighbours in cardinal directions will
  /// always be returned. If the block at `sectionIndex` is at y-level 0 or 255 the down or up neighbours
  /// will be omitted respectively (as there will be none). Otherwise, all neighbours are included.
  ///
  /// - Returns: A mapping from each possible direction to a corresponding block state.
  func getNeighbouringBlockStates(neighbourIndices: [(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]) -> [(Direction, UInt16)] {
    // Convert a section relative index to a chunk relative index
    var neighbouringBlockStates: [(Direction, UInt16)] = []
    neighbouringBlockStates.reserveCapacity(6)
    
    for (faceDirection, neighbourChunkDirection, neighbourIndex) in neighbourIndices {
      if let direction = neighbourChunkDirection {
        if let neighbourChunk = neighbourChunks[direction] {
          neighbouringBlockStates.append((faceDirection, neighbourChunk.getBlockStateId(at: neighbourIndex)))
        }
      } else {
        neighbouringBlockStates.append((faceDirection, chunk.getBlockStateId(at: neighbourIndex)))
      }
    }
    
    return neighbouringBlockStates
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
  
  func getNeighbourLightLevels(neighbourIndices: [(direction: Direction, chunkDirection: CardinalDirection?, index: Int)], visibleFaces: Set<Direction>) -> [Direction: LightLevel] {
    var lightLevels = [Direction: LightLevel](minimumCapacity: 6)
    for (direction, neighbourChunkDirection, neighbourIndex) in neighbourIndices {
      if visibleFaces.contains(direction) {
        if let chunkDirection = neighbourChunkDirection {
          lightLevels[direction] = neighbourChunks[chunkDirection]?.lighting.getLightLevel(at: neighbourIndex) ?? LightLevel()
        } else {
          lightLevels[direction] = chunk.lighting.getLightLevel(at: neighbourIndex)
        }
      }
    }
    return lightLevels
  }
  
  /// Gets an array of the direction of all blocks neighbouring the block at `sectionIndex` that have
  /// full faces facing the block at `sectionIndex`.
  ///
  /// `position` is only used to determine which variation of a block model to use when a block model
  /// has multiple variations. Both `sectionIndex` and `position` are required for performance reasons as this
  /// function is the main bottleneck during mesh preparing.
  ///
  /// - Parameter sectionIndex: The sectionIndex of the block in `chunk`.
  /// - Parameter position: The position of the block relative to `sectionPosition`.
  ///
  /// - Returns: The set of directions of neighbours that can possibly cull a face.
  func getCullingNeighbours(at position: Position, neighbourIndices: [(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]) -> Set<Direction> {
    let neighbouringBlockStates = getNeighbouringBlockStates(neighbourIndices: neighbourIndices)
    
    var cullingNeighbours = Set<Direction>(minimumCapacity: 6)
    
    for (direction, neighbourBlockState) in neighbouringBlockStates where neighbourBlockState != 0 {
      // We assume that block model variants always have the same culling faces as eachother, so no position is passed to getModel.
      guard let blockModel = resources.blockModelPalette.model(for: Int(neighbourBlockState), at: nil) else {
        log.debug("Skipping neighbour with no block models.")
        continue
      }
      
      if blockModel.cullingFaces.contains(direction.opposite) {
        cullingNeighbours.insert(direction)
      }
    }
    
    return cullingNeighbours
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
