//
//  BlockPaletteManager.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import simd
import os

enum BlockPaletteError: LocalizedError {
  case invalidPixlyzerData
}

class BlockPaletteManager {
  var assetManager: AssetManager
  var textureManager: TextureManager
  var cacheManager: CacheManager
  
  var intermediateCache: [Identifier: IntermediateBlockModel] = [:]
  var blockModelPalette: [UInt16: BlockModel] = [:]
  
  init(assetManager: AssetManager, textureManager: TextureManager, cacheManager: CacheManager) throws {
    self.assetManager = assetManager
    self.textureManager = textureManager
    self.cacheManager = cacheManager
    
    if cacheManager.cacheExists(name: "block-palette") {
      Logger.log("loading cached global palette")
      try loadGlobalPaletteCache()
      Logger.log("loaded cached global palette")
    } else {
      Logger.log("generating global palette")
      try generateGlobalPalette()
      Logger.log("caching global palette")
      try cacheGlobalPalette()
      Logger.log("cached global palette")
    }
  }
  
  func loadGlobalPaletteCache() throws {
    let cacheGlobalPalette: CacheBlockModelPalette = try cacheManager.readCache(name: "block-palette")
    
    blockModelPalette = [:]
    for (state, cacheBlockModel) in cacheGlobalPalette.blockModelPalette {
      blockModelPalette[UInt16(state)] = BlockModel(fromCache: cacheBlockModel)
    }
  }
  
  func cacheGlobalPalette() throws {
    var cache = CacheBlockModelPalette()
    for (state, blockModel) in blockModelPalette {
      let cacheBlockModel = blockModel.toCache()
      cache.blockModelPalette[UInt32(state)] = cacheBlockModel
    }
    try cacheManager.writeCache(cache, name: "block-palette")
  }
  
  func generateGlobalPalette() throws {
    let pixlyzerDataFile = assetManager.getPixlyzerFolder().appendingPathComponent("blocks.json")
    guard let pixlyzerJSON = try? JSON.fromURL(pixlyzerDataFile).dict as? [String: [String: Any]] else {
      Logger.error("failed to parse pixlyzer block palette")
      throw BlockPaletteError.invalidPixlyzerData
    }
    for (blockName, block) in pixlyzerJSON {
      let blockJSON = JSON(dict: block)
      if blockJSON.containsKey("render") {
        // IMPLEMENT: multipart
        continue
      }
      
      guard let states = blockJSON.getJSON(forKey: "states")?.dict as? [String: [String: Any]] else {
        Logger.error("invalid pixlyzer json format for \(blockName)")
        throw BlockPaletteError.invalidPixlyzerData
      }
      
      for (stateIdString, state) in states {
        if let stateId = Int(stateIdString) {
          let stateJSON = JSON(dict: state)
          
          // read information about the block models from pixlyzer's data
          var modelJSONs: [JSON] = []
          if let render = stateJSON.getJSON(forKey: "render") {
            modelJSONs = [render]
          } else if let render = stateJSON.getArray(forKey: "render") as? [[String: Any]] {
            modelJSONs = [JSON(dict: render[0])]
            // TODO: handle multiple states for one state id
          } else if let render = stateJSON.getArray(forKey: "render") as? [[[String: Any]]] { // multipart structure
            for modelJSON in render[0] {
              modelJSONs.append(JSON(dict: modelJSON))
            }
            // TODO: handle multiple states for one state id
          }
          
          // process relevant block models
          var blockModels: [BlockModel] = []
          for modelJSON in modelJSONs {
            let modelIdentifierString = modelJSON.getString(forKey: "model")
            let xRot = modelJSON.getInt(forKey: "x") ?? 0
            let yRot = modelJSON.getInt(forKey: "y") ?? 0
            let zRot = modelJSON.getInt(forKey: "z") ?? 0
            let uvlock = modelJSON.getBool(forKey: "uvlock") ?? false
            
            if modelIdentifierString != nil {
              do {
                let modelIdentifier = try Identifier(modelIdentifierString!)
                let blockModel = try loadBlockModel(for: modelIdentifier, xRot: xRot, yRot: yRot, zRot: zRot, uvlock: uvlock)
                blockModels.append(blockModel)
              } catch {
                Logger.error("failed to load model for \(modelIdentifierString!): \(error)")
              }
            } else {
              // TODO: multipart structures
              Logger.error("failed to find model identifier for state \(stateId) on block \(blockName)")
            }
          }
          
          // combine the block models into one (for multipart structures)
          var combinedBlockModel = BlockModel(fullFaces: Set<FaceDirection>(), elements: [])
          for blockModel in blockModels {
            combinedBlockModel.elements.append(contentsOf: blockModel.elements)
            combinedBlockModel.fullFaces.formUnion(blockModel.fullFaces)
          }
          
          // add to palette
          blockModelPalette[UInt16(stateId)] = combinedBlockModel
        } else {
          Logger.error("invalid state id: \(stateIdString)")
        }
      }
    }
    
    intermediateCache = [:]
  }
  
  func loadBlockModel(for identifier: Identifier, xRot: Int, yRot: Int, zRot: Int, uvlock: Bool) throws -> BlockModel {
    // IMPLEMENT: block model rotations
    let intermediate = try loadIntermediateBlockModel(for: identifier)
    
    let rotationMatrix = MatrixUtil.rotationMatrix(x: Float(xRot) / 180 * Float.pi)
      * MatrixUtil.rotationMatrix(y: Float(yRot) / 180 * Float.pi)
      * MatrixUtil.rotationMatrix(z: Float(zRot) / 180 * Float.pi)
    
    let modelMatrix = MatrixUtil.translationMatrix([-0.5, -0.5, -0.5])
      * rotationMatrix
      * MatrixUtil.translationMatrix([0.5, 0.5, 0.5])
    
    var fullFaces = Set<FaceDirection>()
    var elements: [BlockModelElement] = []
    for intermediateElement in intermediate.elements {
      var faces: [FaceDirection: BlockModelElementFace] = [:]
      for (direction, intermediateFace) in intermediateElement.faces {
        if let textureIdentifier = try? Identifier(intermediateFace.textureVariable) {
          if let textureIndex = textureManager.identifierToBlockTextureIndex[textureIdentifier] {
            var cullface = intermediateFace.cullface
            if cullface != nil {
              let vector = simd_float4(cullface!.toVector(), 1) * rotationMatrix
              cullface = FaceDirection.fromVector(vector: simd_make_float3(vector))
            }
            
            var rotation = intermediateFace.rotation
            if uvlock {
              switch direction.axis {
                case .x:
                  rotation += xRot
                  
                  if zRot == 180 {
                    rotation += 180
                  }
                case .y:
                  // y rotates the other way in my code for some reason
                  rotation -= yRot
                case .z:
                  rotation += zRot
                  
                  if xRot == 180 {
                    rotation += 180
                  }
              }
            }
            
            rotation = rotation % 360
            
            let minUV = intermediateFace.uv.0
            let maxUV = intermediateFace.uv.1
            let uvs = textureCoordsFrom(minUV, maxUV, rotation: -rotation) // minecraft does rotation the other way
            
            let face = BlockModelElementFace(
              uvs: uvs,
              textureIndex: textureIndex,
              cullface: cullface,
              tintIndex: Int8(intermediateFace.tintIndex ?? -1)
            )
            faces[direction] = face
          } else {
            // most likely an animated texture
          }
        } else {
          Logger.error("invalid texture variable: \(intermediateFace.textureVariable) on \(identifier)")
        }
      }
      let modelMatrix = intermediateElement.modelMatrix * modelMatrix
      let element = BlockModelElement(modelMatrix: modelMatrix, faces: faces)
      elements.append(element)
      
      // check if block has any full faces
      
      let point1 = simd_make_float3(simd_float4(0, 0, 0, 1) * modelMatrix)
      let point2 = simd_make_float3(simd_float4(1, 1, 1, 1) * modelMatrix)
      
      for direction in FaceDirection.directions {
        // 0 if the direction is a negative direction, otherwise 1
        let value = (simd_dot(direction.toVector(), simd_float3(repeating: 1)) + 1) / 2.0
        
        let maxPoint: simd_float2
        let minPoint: simd_float2
        switch direction.axis {
          case .x:
            if point1.x != value && point2.x != value {
              continue
            }
            maxPoint = simd_float2(max(point1.y, point2.y), max(point1.z, point2.z))
            minPoint = simd_float2(min(point1.y, point2.y), min(point1.z, point2.z))
          case .y:
            if point1.y != value && point2.y != value {
              continue
            }
            maxPoint = simd_float2(max(point1.x, point2.x), max(point1.z, point2.z))
            minPoint = simd_float2(min(point1.x, point2.x), min(point1.z, point2.z))
          case .z:
            if point1.z != value && point2.z != value {
              continue
            }
            maxPoint = simd_float2(max(point1.x, point2.x), max(point1.y, point2.y))
            minPoint = simd_float2(min(point1.x, point2.x), min(point1.y, point2.y))
        }
        
        if minPoint.x <= 0 && minPoint.y <= 0 && maxPoint.x >= 1 && maxPoint.y >= 1 {
          fullFaces.insert(direction)
        }
      }
    }
    
    let blockModel = BlockModel(fullFaces: fullFaces, elements: elements)
    return blockModel
  }
  
  func loadIntermediateBlockModel(for identifier: Identifier) throws -> IntermediateBlockModel {
    if let blockModel = intermediateCache[identifier] {
      return blockModel
    }
    
    let blockModelJSON = try assetManager.getModelJSON(for: identifier)
    var parent: IntermediateBlockModel? = nil
    if let parentName = blockModelJSON.getString(forKey: "parent") {
      parent = try loadIntermediateBlockModel(for: try Identifier(parentName))
    }
    
    _ = blockModelJSON.getString(forKey: "ambientocclusion")
    
    let textures = (blockModelJSON.getJSON(forKey: "textures")?.dict as? [String: String]) ?? [:]
    
    var elements: [IntermediateBlockModelElement] = []
    if let elementDicts = blockModelJSON.getArray(forKey: "elements") as? [[String: Any]] {
      for elementDict in elementDicts {
        let elementJSON = JSON(dict: elementDict)
        
        let from = (elementJSON.getArray(forKey: "from") as? [Double] ?? []).map {
          return Float($0)
        }
        let to = (elementJSON.getArray(forKey: "to") as? [Double] ?? []).map {
          return Float($0)
        }
        
        let rotationJSON = elementJSON.getJSON(forKey: "rotation")
        let hasRotation = rotationJSON != nil
        let rotationOrigin = (rotationJSON?.getArray(forKey: "origin") as? [Double] ?? []).map {
          return Float($0)
        }
        let rotationAxis = rotationJSON?.getString(forKey: "axis")
        let angle = rotationJSON?.getFloat(forKey: "angle")
        _ = rotationJSON?.getBool(forKey: "rescale") ?? false
        
        _ = elementJSON.getBoolString(forKey: "shade")
        
        var faces: [FaceDirection: IntermediateBlockModelElementFace] = [:]
        let facesDict = (elementJSON.getJSON(forKey: "faces")?.dict as? [String: [String: Any]]) ?? [:]
        for (faceName, faceDict) in facesDict {
          if let direction = FaceDirection(string: faceName) {
            let faceJSON = JSON(dict: faceDict)
            
            var uv: [Float] = []
            if let uvArray = faceJSON.getArray(forKey: "uv") as? [Float] {
              uv = uvArray
            } else { // calculate the uv coordinates from from and to
              switch direction {
                case .west:
                  uv = [
                    from[2],
                    16 - to[1],
                    to[2],
                    16 - from[1]
                  ]
                case .east:
                  uv = [
                    16 - to[2],
                    16 - to[1],
                    16 - from[2],
                    16 - from[1]
                  ]
                case .down:
                  uv = [
                    from[0],
                    16 - to[2],
                    to[0],
                    16 - from[2]
                  ]
                case .up:
                  uv = [
                    from[0],
                    from[2],
                    to[0],
                    to[2]
                  ]
                case .south:
                  uv = [
                    from[0],
                    16 - to[1],
                    to[0],
                    16 - from[1]
                  ]
                case .north:
                  uv = [
                    16 - to[0],
                    16 - to[1],
                    16 - from[0],
                    16 - from[1]
                  ]
              }
            }
            let cullface = faceJSON.getString(forKey: "cullface")
            let rotation = faceJSON.getInt(forKey: "rotation") ?? 0
            let tintIndex = faceJSON.getInt(forKey: "tintindex")
            
            if let textureVariable = faceJSON.getString(forKey: "texture") {
              var texture = textureVariable
              if texture.starts(with: "#") {
                let textureVariable = String(texture.dropFirst())
                texture = textures[textureVariable] ?? texture
              }
              if uv.count == 4 {
                let textureCoordinates = (
                  simd_float2(uv[0], uv[1]) / 16.0,
                  simd_float2(uv[2], uv[3]) / 16.0
                )
                let face = IntermediateBlockModelElementFace(
                  uv: textureCoordinates,
                  textureVariable: texture,
                  cullface: cullface != nil ? FaceDirection(string: cullface!) : nil,
                  rotation: rotation,
                  tintIndex: tintIndex
                )
                faces[direction] = face
              } else {
                // IMPLEMENT: automatic uv generation
                Logger.error("invalid uv \(uv)")
              }
            } else {
              Logger.error("block model element doesn't specify texture")
            }
          } else {
            Logger.error("invalid face direction: \(faceName)")
          }
        }
        
        if from.count == 3 && to.count == 3 {
          // scaling and translation
          let fromVector = simd_float3(from)
          let toVector = simd_float3(to)
          let scale = (toVector - fromVector) / Float(16.0)
          let origin = fromVector / Float(16.0)
          
          var modelMatrix = matrix_float4x4(1) // identity matrix
          modelMatrix *= MatrixUtil.scalingMatrix(scale.x, scale.y, scale.z)
          modelMatrix *= MatrixUtil.translationMatrix(origin)
          
          // TODO: rescale
//          if rescale {
//            modelMatrix *= MatrixUtil.scalingMatrix(1.414, 1, 1.414)
//          }
          
          // rotation
          if hasRotation {
            if rotationOrigin.count == 3 {
              let rotationOriginVector = simd_float3(rotationOrigin) / Float(16.0)
              let rotation = angle != nil ? Float(angle!) / 180 * Float.pi : 0
              modelMatrix *= MatrixUtil.translationMatrix(-rotationOriginVector)
              switch rotationAxis {
                case "x":
                  modelMatrix *= MatrixUtil.rotationMatrix(x: rotation)
                case "y":
                  modelMatrix *= MatrixUtil.rotationMatrix(y: rotation)
                case "z":
                  modelMatrix *= MatrixUtil.rotationMatrix(z: rotation)
                default:
                  Logger.error("invalid rotation axis")
              }
              modelMatrix *= MatrixUtil.translationMatrix(rotationOriginVector)
            } else {
              Logger.error("invalid rotation on block model element")
            }
          }
          
          let element = IntermediateBlockModelElement(
            modelMatrix: modelMatrix,
            faces: faces
          )
          elements.append(element)
        } else {
          Logger.error("invalid from or to on \(identifier). \(from), \(to)")
        }
      }
    } else {
      elements = parent?.elements ?? []
      for (index, var element) in elements.enumerated() {
        for (direction, var face) in element.faces {
          var texture = face.textureVariable
          if texture.starts(with: "#") {
            let textureVariable = String(texture.dropFirst())
            texture = textures[textureVariable] ?? texture
          }
          face.textureVariable = texture
          element.faces[direction] = face
        }
        elements[index] = element
      }
    }
    
    let blockModel = IntermediateBlockModel(elements: elements)
    intermediateCache[identifier] = blockModel // cache block model for later
    return blockModel
  }
  
  private func textureCoordsFrom(_ minUV: simd_float2, _ maxUV: simd_float2, rotation: Int) -> [simd_float2] {
    // one uv coordinate for each corner
    var uvs = [
      simd_float2(maxUV.x, minUV.y),
      maxUV,
      simd_float2(minUV.x, maxUV.y),
      minUV
    ]
    
    // rotate the texture coordinates
    if rotation != 0 {
      let textureCenter = simd_float2(0.5, 0.5)
      let matrix = MatrixUtil.rotationMatrix2d(Float(rotation) / 180 * Float.pi)
      for (index, var uv) in uvs.enumerated() {
        uv -= textureCenter
        uv = uv * matrix
        uv += textureCenter
        uvs[index] = uv
      }
    }
    
    return uvs
  }
}
