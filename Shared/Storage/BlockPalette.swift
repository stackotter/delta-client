//
//  BlockPalette.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore
import simd

/// A palette holding information about all block states and block models.
public struct BlockPalette {
  /// A dictionary mapping block identifier to block information.
  public private(set) var blocks: [Identifier: Block]
  /// The array of all block states (indexed by block state id).
  public private(set) var blockStates: [BlockState]
  /// The texture palette holding the block textures.
  public private(set) var blockTexturePalette: TexturePalette
  /// The array containing all the different transformation matrices used for different blocks in specific conditions.
  public private(set) var blockDisplayTransforms: [BlockModelDisplayTransforms]
  /// The array of all block models (indexed by block state id). Each block state is associated
  /// with 1 or more variants. Each variant contains an array of block models which contains
  /// multiple models if the variant is a multipart structure.
  public private(set) var blockModels: [[[BlockModel]]]
  
  // MARK: Init
  
  private init(
    blocks: [Identifier : Block],
    blockStates: [BlockState],
    blockTexturePalette: TexturePalette,
    blockDisplayTransforms: [BlockModelDisplayTransforms],
    blockModels: [[[BlockModel]]]
  ) {
    self.blocks = blocks
    self.blockStates = blockStates
    self.blockTexturePalette = blockTexturePalette
    self.blockDisplayTransforms = blockDisplayTransforms
    self.blockModels = blockModels
  }
  
  // MARK: Parsing
  
  /// Parses the block palette described by the given pixlyzer data file and the block models in the specified directory.
  public static func parse(
    from pixlyzerDataFile: URL,
    withBlockModelFiles blockModelDirectory: URL,
    and blockTexturePalette: TexturePalette
  ) throws -> BlockPalette {
    // Read global block palette from the pixlyzer block palette.
    let data = try Data(contentsOf: pixlyzerDataFile)
    let pixlyzerPalette = try JSONDecoder().decode(PixlyzerBlockPalette.self, from: data)
    
    // Read block models from current resource pack
    let mojangBlockModels: [Identifier: MojangBlockModel] = try readMojangBlockModels(from: blockModelDirectory)
    // Flatten the mojang formatted block models
    let flatMojangBlockModelPalette = try FlatMojangBlockModelPalette(from: mojangBlockModels)
    
    // Convert the pixlyzer data to a slightly nicer format.
    var blocks: [Identifier: Block] = [:]
    var blockStates: [BlockState] = []
    var blockModels: [[[BlockModel]]] = []
    for (identifier, pixlyzerBlock) in pixlyzerPalette.palette {
      let block = pixlyzerBlock.getBlock()
      let states = pixlyzerBlock.getBlockStates()
      
      // Get the block models for this block's states and variants
      let pixlyzerBlockModels = pixlyzerBlock.blockModels
      // Maps block state id to an array of variants. Each model variant as an array of models
      // which contains multiple models only if the model is a multipart structure.
      let blockStateToBlockModelVariants: [Int: [[BlockModel]]] = try pixlyzerBlockModels.mapValues { variants in
        let blockModelVariants = try variants.map { variant in
          try multipartBlockModel(for: variant, from: flatMojangBlockModelPalette, with: blockTexturePalette)
        }
        return blockModelVariants
      }
      
      blocks[identifier] = block
      blockStates.append(contentsOf: states)
      blockModels.append(contentsOf: blockStateToBlockModelVariants.values)
    }
    
    return BlockPalette(
      blocks: blocks,
      blockStates: blockStates,
      blockTexturePalette: blockTexturePalette,
      blockDisplayTransforms: flatMojangBlockModelPalette.displayTransforms,
      blockModels: blockModels)
  }
  
  /// Creates the block model for the given pixlyzer block model.
  /// If it is not a multi part structure the return value has a count of 1.
  private static func multipartBlockModel(
    for pixlyzerBlockModel: PixlyzerBlockModel,
    from flatMojangBlockModelPalette: FlatMojangBlockModelPalette,
    with blockTexturePalette: TexturePalette
  ) throws -> [BlockModel] {
    let partDescriptors = pixlyzerBlockModel.parts
    let models: [BlockModel] = try partDescriptors.map { modelDescriptor in
      // Get the block model data in its intermediate 'flattened' format
      guard let flatModel = flatMojangBlockModelPalette.blockModel(for: modelDescriptor.model) else {
        throw BlockPaletteError.invalidIdentifier
      }
      
      let modelRotationMatrix = modelDescriptor.rotationMatrix
      
      // Convert the elements to the correct format and identify culling faces
      var cullingFaces: Set<Direction> = []
      let elements: [BlockModelElement] = try flatModel.elements.map { flatElement in
        // Identify any faces of the elements that can fill a whole side of a block
        let elementCullingFaces = flatElement.getCullingFaces()
        cullingFaces.formUnion(elementCullingFaces)
        
        // TODO: most of the functions in here can probably become initializers
        return try blockModelElement(
          from: flatElement,
          with: blockTexturePalette,
          andRotatedBy: modelRotationMatrix,
          uvLock: modelDescriptor.uvLock ?? false)
      }
      
      // Rotate the culling face directions to correctly match the block
      cullingFaces = Set<Direction>(cullingFaces.map { direction in
        direction.rotated(modelRotationMatrix)
      })
      
      return BlockModel(
        cullingFaces: Set(cullingFaces),
        ambientOcclusion: flatModel.ambientOcclusion,
        displayTransformsIndex: flatModel.displayTransformsIndex,
        elements: elements)
    }
    
    return models
  }
  
  /// Converts a flattened block model element to a block model element format ready for rendering.
  private static func blockModelElement(
    from flatElement: FlatMojangBlockModelElement,
    with blockTexturePalette: TexturePalette,
    andRotatedBy modelRotationMatrix: matrix_float4x4,
    uvLock: Bool
  ) throws -> BlockModelElement {
    // Create the matrix used to create face normals
    let normalRotationMatrix = (flatElement.rotation?.matrix ?? MatrixUtil.identity) * modelRotationMatrix
    
    // Convert the faces to the correct format
    let faces: [BlockModelFace] = try flatElement.faces.map { flatFace in
      // Get the index of the face's texture
      let textureIdentifier = try Identifier(flatFace.texture)
      guard let textureIndex = blockTexturePalette.textureIndex(for: textureIdentifier) else {
        throw BlockPaletteError.invalidTextureIdentifier(textureIdentifier)
      }
      
      // Create the face normal from the face direction and block rotation
      var normal = simd_float4(flatFace.direction.toVector(), 1)
      normal = normal * normalRotationMatrix
      
      // Update the cullface with the block rotation
      var cullface: Direction? = nil
      if let flatCullface = flatFace.cullface {
        cullface = flatCullface.rotated(modelRotationMatrix)
      }
      
      let uvs = try uvsForFace(
        facing: flatFace.direction,
        onElementFrom: flatElement.from,
        to: flatElement.to,
        rotatedBy: flatFace.textureRotation,
        uvLock: uvLock)
      
      return BlockModelFace(
        direction: flatFace.direction,
        uv: uvs,
        texture: textureIndex,
        cullface: cullface,
        normal: simd_make_float3(normal),
        tintIndex: flatFace.tintIndex)
    }
    
    return BlockModelElement(
      transformation: flatElement.transformationMatrix,
      shade: flatElement.shade,
      faces: faces)
  }
  
  /// Calculates texture uvs for a face from an element's bounds and the face's direction.
  private static func uvsForFace(
    facing direction: Direction,
    onElementFrom minimumPoint: simd_float3,
    to maximumPoint: simd_float3,
    rotatedBy rotation: Int,
    uvLock: Bool
  ) throws -> (simd_float2, simd_float2) {
    // Here's a big ugly switch statement I made just for you, you're welcome
    var uvs: [Float]
    switch direction {
      case .west:
        uvs = [
          minimumPoint.z,
          1 - maximumPoint.y,
          maximumPoint.z,
          1 - minimumPoint.y
        ]
      case .east:
        uvs = [
          1 - maximumPoint.z,
          1 - maximumPoint.y,
          1 - minimumPoint.z,
          1 - minimumPoint.y
        ]
      case .down:
        uvs = [
          minimumPoint.x,
          1 - maximumPoint.z,
          maximumPoint.x,
          1 - minimumPoint.z
        ]
      case .up:
        uvs = [
          minimumPoint.x,
          minimumPoint.z,
          maximumPoint.x,
          maximumPoint.z
        ]
      case .south:
        uvs = [
          minimumPoint.x,
          1 - maximumPoint.y,
          maximumPoint.x,
          1 - minimumPoint.y
        ]
      case .north:
        uvs = [
          1 - maximumPoint.x,
          1 - maximumPoint.y,
          1 - minimumPoint.x,
          1 - minimumPoint.y
        ]
    }
    
    // TODO: uvlock
    
    // Rotation is in degrees and measured clockwise (silly Mojang)
    switch rotation {
      case 0:
        return (
          simd_float2(uvs[0], uvs[1]),
          simd_float2(uvs[2], uvs[3]))
      case 90:
        return (
          simd_float2(uvs[0], uvs[1]),
          simd_float2(uvs[2], uvs[3]))
      case 180:
        return (
          simd_float2(uvs[0], uvs[1]),
          simd_float2(uvs[2], uvs[3]))
      case 270:
        return (
          simd_float2(uvs[0], uvs[1]),
          simd_float2(uvs[2], uvs[3]))
      default:
        throw BlockPaletteError.invalidTextureRotation(degrees: rotation)
    }
  }
  
  /// Returns a dictionary containing all of the block models in the specified directory (in Mojang's format).
  private static func readMojangBlockModels(from directory: URL) throws -> [Identifier: MojangBlockModel] {
    var mojangBlockModels: [Identifier: MojangBlockModel] = [:]
    
    let files = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: .skipsSubdirectoryDescendants)
    for file in files where file.pathExtension == "json" {
      let blockName = file.deletingPathExtension().lastPathComponent
      let identifier = Identifier(name: "block/\(blockName)")
      let data = try Data(contentsOf: file)
      let mojangBlockModel = try JSONDecoder().decode(MojangBlockModel.self, from: data)
      mojangBlockModels[identifier] = mojangBlockModel
    }
    
    return mojangBlockModels
  }
}
