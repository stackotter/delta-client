import Foundation
import MetalKit
import simd

// TODO: why is this a class
public class ChunkSectionMesh: Mesh {
  /// A lookup to quickly convert block index to block position
  private static let indexToPosition = generateIndexLookup()
  
  private static let indexToNeighbourIndicesLookup = (0..<Chunk.numSections).map { generateNeighbourIndices(sectionIndex: $0) }
  
  /// The `Chunk` containing the `Chunk.Section` to prepare
  public var chunk: Chunk
  /// The position of the `Chunk.Section` to prepare
  public var sectionPosition: ChunkSectionPosition
  /// The chunks surrounding `chunk`
  public var neighbourChunks: [CardinalDirection: Chunk]
  
  private let resourcePack: ResourcePack
  private let resources: ResourcePack.Resources
  public var stopwatch = Stopwatch(mode: .summary, name: "ChunkSectionMesh")
  
  public init(
    forSectionAt sectionPosition: ChunkSectionPosition,
    in chunk: Chunk,
    withNeighbours neighbourChunks: [CardinalDirection: Chunk],
    resourcePack: ResourcePack
  ) {
    self.sectionPosition = sectionPosition
    self.chunk = chunk
    self.neighbourChunks = neighbourChunks
    self.resourcePack = resourcePack
    self.resources = resourcePack.vanillaResources
    super.init()
  }
  
  /// Prepares the `Chunk.Section` at `sectionPosition` into the mesh
  public func prepare() {
    vertices = []
    indices = []
    
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
          addBlock(at: position, atBlockIndex: blockIndex, with: state, indexToNeighbourIndices: indexToNeighbourIndices)
        }
      }
      let elapsed = CFAbsoluteTimeGetCurrent() - startTime
      log.debug("Prepared ChunkSectionMesh for Chunk.Section at \(sectionPosition) in \(elapsed) seconds")
    }
    
    // generate model to world transformation matrix
    let position = simd_float3(
      Float(sectionPosition.sectionX) * 16,
      Float(sectionPosition.sectionY) * 16,
      Float(sectionPosition.sectionZ) * 16)
    let modelToWorldMatrix = MatrixUtil.translationMatrix(position)
    
    // set the mesh uniforms
    uniforms = Uniforms(transformation: modelToWorldMatrix)
  }
  
  /// Adds a block to the mesh at `position` with block state `state`.
  private func addBlock(
    at position: Position,
    atBlockIndex blockIndex: Int,
    with state: UInt16,
    indexToNeighbourIndices: [[(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]]
  ) {
//    stopwatch.startMeasurement("get block models")
    let state = Int(state)
    guard let blockModel = resources.blockModelPalette.getModel(for: state, at: position) else {
      log.warning("Skipping block with no block models")
      return
    }
    
    guard let block = chunk.blockRegistry.getBlockForState(withId: state) else {
      log.warning("Skipping block with non-existent id \(state)")
      return
    }
//    stopwatch.stopMeasurement("get block models")
    
    if blockModel.cullableFaces.isEmpty && blockModel.nonCullableFaces.isEmpty {
      return
    }
    
//    stopwatch.startMeasurement("calculate neighbour indices")
    let neighbourIndices = indexToNeighbourIndices[blockIndex]
//    stopwatch.stopMeasurement("calculate neighbour indices")
    
//    stopwatch.startMeasurement("get culling neighbours")
    let cullFaces = getCullingNeighbours(ofBlock: block, at: position, neighbourIndices: neighbourIndices)
//    stopwatch.stopMeasurement("get culling neighbours")
    
//    stopwatch.startMeasurement("calculate face visibility")
    if blockModel.cullableFaces.count == 6 && cullFaces.count == 6 && blockModel.nonCullableFaces.count == 0 {
//      stopwatch.stopMeasurement("calculate face visibility")
      return
    }
    
    var visibleFaces = blockModel.cullableFaces.subtracting(cullFaces)
    
    if blockModel.nonCullableFaces.isEmpty && visibleFaces.isEmpty {
//      stopwatch.stopMeasurement("calculate face visibility")
      return
    }
    
    if !blockModel.nonCullableFaces.isEmpty {
      visibleFaces = visibleFaces.union(blockModel.nonCullableFaces)
    }
    
//    stopwatch.stopMeasurement("calculate face visibility")
    
    if visibleFaces.isEmpty {
      return
    }
    
//    stopwatch.startMeasurement("get light level")
    let lightLevel = chunk.lighting.getLightLevel(at: position.relativeToChunkSection, inSectionAt: sectionPosition.sectionY)
//    stopwatch.stopMeasurement("get light level")
    
//    stopwatch.startMeasurement("get neighbour light levels")
    let neighbourLightLevels = getNeighbourLightLevels(neighbourIndices: neighbourIndices, visibleFaces: visibleFaces)
//    stopwatch.stopMeasurement("get neighbour light levels")
    
//    stopwatch.startMeasurement("add block models")
    let offset = block.getModelOffset(at: position)
    let modelToWorld = MatrixUtil.translationMatrix(position.relativeToChunkSection.floatVector + offset)
    for part in blockModel.parts {
      addModelPart(part, transformedBy: modelToWorld, cullFaces: cullFaces, lightLevel: lightLevel, neighbourLightLevels: neighbourLightLevels)
    }
//    stopwatch.stopMeasurement("add block models")
  }
  
  /// Adds the given block model to the mesh, positioned by the given model to world matrix.
  private func addModelPart(
    _ blockModel: BlockModelPart,
    transformedBy modelToWorld: matrix_float4x4,
    cullFaces: Set<Direction>,
    lightLevel: LightLevel,
    neighbourLightLevels: [Direction: LightLevel]
  ) {
    for element in blockModel.elements {
      addElement(element, transformedBy: modelToWorld, cullFaces: cullFaces, lightLevel: lightLevel, neighbourLightLevels: neighbourLightLevels)
    }
  }
  
  /// Adds the given blok model element to the mesh, positioned by the given model to world matrix.
  private func addElement(
    _ element: BlockModelElement,
    transformedBy modelToWorld: matrix_float4x4,
    cullFaces: Set<Direction>,
    lightLevel: LightLevel,
    neighbourLightLevels: [Direction: LightLevel]
  ) {
    let vertexToWorld = element.transformation * modelToWorld
    
    for face in element.faces {
      if let cullFace = face.cullface, cullFaces.contains(cullFace) {
        continue
      }
      var faceLightLevel = neighbourLightLevels[face.actualDirection] ?? LightLevel()
      faceLightLevel = LightLevel.max(faceLightLevel, lightLevel)
      addFace(face, transformedBy: vertexToWorld, shouldShade: element.shade, lightLevel: faceLightLevel)
    }
  }
  
  /// Adds the face described by `face` to the mesh, facing in `direction` and transformed by `transformation`.
  private func addFace(
    _ face: BlockModelFace,
    transformedBy transformation: matrix_float4x4,
    shouldShade: Bool,
    lightLevel: LightLevel
  ) {
    // Add face winding
    let offset = UInt32(vertices.count) // The index of the first vertex of face
    for index in CubeGeometry.faceWinding {
      indices.append(index &+ offset)
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
    
    // Add vertices to mesh
    let textureIndex = UInt16(face.texture)
    let isTinted = face.tintIndex == 0
    let tint = (isTinted ? simd_float3(0.53, 0.75, 0.38) : simd_float3(1, 1, 1)) * shade
    
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
      vertices.append(vertex)
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
  func getCullingNeighbours(ofBlock block: Block, at position: Position, neighbourIndices: [(direction: Direction, chunkDirection: CardinalDirection?, index: Int)]) -> Set<Direction> {
    let neighbouringBlockStates = getNeighbouringBlockStates(neighbourIndices: neighbourIndices)
    
    var cullingNeighbours = Set<Direction>(minimumCapacity: 6)
    
    let isLeaves = block.className == "LeavesBlock"
    
    for (direction, neighbourBlockState) in neighbouringBlockStates where neighbourBlockState != 0 {
      // We assume that block model variants always have the same culling faces as eachother
      let neighbourState = Int(neighbourBlockState)
      
      guard let neighbourBlock = chunk.blockRegistry.getBlockForState(withId: neighbourState) else {
        log.warning("Skipping neighbour with non-existent block state id: \(neighbourState), returning no cull faces")
        continue
      }
      
      // Cull the faces between two leaves blocks of the same type
      if isLeaves && block.id == neighbourBlock.id {
        cullingNeighbours.insert(direction)
        continue
      }
      
      guard let blockModel = resources.blockModelPalette.getModel(for: neighbourState, at: nil) else {
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
