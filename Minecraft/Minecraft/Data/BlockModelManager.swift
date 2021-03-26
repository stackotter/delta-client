//
//  BlockModelManager.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/3/21.
//

import Foundation
import simd
import os

enum BlockModelError: LocalizedError {
  case invalidPixlyzerData
}

enum FaceDirection: String {
  case down = "down"
  case up = "up"
  case north = "north"
  case south = "south"
  case west = "west"
  case east = "east"
  
  func toVector() -> simd_float3 {
    switch self {
      case .down:
        return simd_float3(0, -1, 0)
      case .up:
        return simd_float3(0, 1, 0)
      case .north:
        return simd_float3(0, 0, -1)
      case .south:
        return simd_float3(0, 0, 1)
      case .west:
        return simd_float3(-1, 0, 0)
      case .east:
        return simd_float3(1, 0, 0)
    }
  }
  
  static func fromVector(vector: simd_float3) -> FaceDirection {
    let x = vector.x.rounded()
    let y = vector.y.rounded()
    let z = vector.z.rounded()
    
    if x == 1 {
      return .east
    } else if x == -1 {
      return .west
    } else if z == 1 {
      return .south
    } else if z == -1 {
      return .north
    } else if y == 1 {
      return .up
    } else if y == -1 {
      return .down
    }
    
    Logger.debug("vector \(vector) did not match a direction")
    return .up
  }
}

// an intermediate block model used before global palette is loaded
struct IntermediateBlockModelElementFace {
  var uv: (simd_float2, simd_float2)
  var textureVariable: String
  var cullface: FaceDirection?
  var rotation: Int
  var tintIndex: Int?
}

struct IntermediateBlockModelElement {
  var modelMatrix: simd_float4x4
  var faces: [FaceDirection: IntermediateBlockModelElementFace]
}

struct IntermediateBlockModel {
  var elements: [IntermediateBlockModelElement]
}

// the actual block model structure used for rendering
struct BlockModelElementFace {
  var uv: (simd_float2, simd_float2)
  var textureIndex: UInt16 // the index of the texture to use in the block texture buffer
  var cullface: FaceDirection?
  var rotation: Int
  var tintIndex: Int?
}

struct BlockModelElement {
  var modelMatrix: simd_float4x4
  var faces: [FaceDirection: BlockModelElementFace]
}

struct BlockModel {
  var elements: [BlockModelElement]
}


// TODO: think of a better name for BlockModelManager
class BlockModelManager {
  var assetManager: AssetManager
  var textureManager: TextureManager
  
  var intermediateCache: [Identifier: IntermediateBlockModel] = [:]
  var blockModelPalette: [UInt16: BlockModel] = [:]
  
  init(assetManager: AssetManager, textureManager: TextureManager) {
    self.assetManager = assetManager
    self.textureManager = textureManager
  }
  
  func loadGlobalPalette() throws {
    let pixlyzerDataFile = assetManager.getPixlyzerFolder()!.appendingPathComponent("blocks.json")
    guard let pixlyzerJSON = try? JSON.fromURL(pixlyzerDataFile).dict as? [String: [String: Any]] else {
      Logger.error("failed to parse pixlyzer block palette")
      throw BlockModelError.invalidPixlyzerData
    }
    for (blockName, block) in pixlyzerJSON {
      let blockJSON = JSON(dict: block)
      if blockJSON.containsKey("render") {
        // IMPLEMENT: multipart
        continue
      }
      
      guard let states = blockJSON.getJSON(forKey: "states")?.dict as? [String: [String: Any]] else {
        Logger.error("invalid pixlyzer json format")
        throw BlockModelError.invalidPixlyzerData
      }
      
      for (stateIdString, state) in states {
        if let stateId = Int(stateIdString) {
          let stateJSON = JSON(dict: state)
          var modelIdentifierString: String? = nil
          var x: Float = 0
          var y: Float = 0
          var z: Float = 0
          
          if let render = stateJSON.getJSON(forKey: "render") {
            modelIdentifierString = render.getString(forKey: "model")
            x = Float(render.getInt(forKey: "x") ?? 0)
            y = Float(render.getInt(forKey: "y") ?? 0)
            z = Float(render.getInt(forKey: "z") ?? 0)
          } else if let render = stateJSON.getArray(forKey: "render") as? [[String: Any]] {
            // IMPLEMENT: handling multiple states for one state id
            let json = JSON(dict: render[0])
            modelIdentifierString = json.getString(forKey: "model")
            x = Float(json.getInt(forKey: "x") ?? 0)
            y = Float(json.getInt(forKey: "y") ?? 0)
            z = Float(json.getInt(forKey: "z") ?? 0)
          }
          
          x = x / 180 * Float.pi
          y = y / 180 * Float.pi
          z = z / 180 * Float.pi
          
          let rotationMatrix = MatrixUtil.rotationMatrix(x: x) * MatrixUtil.rotationMatrix(y: y) * MatrixUtil.rotationMatrix(z: z)
          let modelMatrix = MatrixUtil.translationMatrix([-0.5, -0.5, -0.5]) * rotationMatrix * MatrixUtil.translationMatrix([0.5, 0.5, 0.5])
//          let rotationMatrix = matrix_float4x4(1)
//          let modelMatrix = matrix_float4x4(1)
          
          if modelIdentifierString != nil {
            do {
              let modelIdentifier = try Identifier(modelIdentifierString!)
              var blockModel = try loadBlockModel(for: modelIdentifier)
              
              if modelMatrix != matrix_float4x4(1) {
                for (index, var element) in blockModel.elements.enumerated() {
                  element.modelMatrix *= modelMatrix
                  for (faceIndex, var face) in element.faces {
                    if var cullface = face.cullface {
                      let vector = simd_float4(cullface.toVector(), 1) * rotationMatrix
                      cullface = FaceDirection.fromVector(vector: simd_make_float3(vector))
                      face.cullface = cullface
                      element.faces[faceIndex] = face
                    }
                  }
                  blockModel.elements[index] = element
                }
              }
              
              blockModelPalette[UInt16(stateId)] = blockModel
            } catch {
              Logger.error("failed to load model for \(modelIdentifierString!): \(error)")
            }
          } else {
            Logger.error("failed to find model identifier for state \(stateId) on block \(blockName)")
          }
        } else {
          Logger.error("invalid state id: \(stateIdString)")
        }
      }
    }
    
    intermediateCache = [:]
    
    Logger.debug("model matrix birch: \(blockModelPalette[80]!.elements[0].modelMatrix)")
  }
  
  func loadBlockModel(for identifier: Identifier) throws -> BlockModel {
    // IMPLEMENT: block model rotations
    let intermediate = try loadIntermediateBlockModel(for: identifier)
    var elements: [BlockModelElement] = []
    for intermediateElement in intermediate.elements {
      var faces: [FaceDirection: BlockModelElementFace] = [:]
      for (direction, intermediateFace) in intermediateElement.faces {
        if let textureIdentifier = try? Identifier(intermediateFace.textureVariable) {
          if let textureIndex = textureManager.identifierToBlockTextureIndex[textureIdentifier] {
            let face = BlockModelElementFace(
              uv: intermediateFace.uv,
              textureIndex: textureIndex,
              cullface: intermediateFace.cullface,
              rotation: intermediateFace.rotation,
              tintIndex: intermediateFace.tintIndex
            )
            faces[direction] = face
          } else {
            // most likely an animated texture
          }
        } else {
          Logger.error("invalid texture variable: \(intermediateFace.textureVariable) on \(identifier)")
        }
      }
      let element = BlockModelElement(modelMatrix: intermediateElement.modelMatrix, faces: faces)
      elements.append(element)
    }
    let blockModel = BlockModel(elements: elements)
    return blockModel
  }
  
  func loadIntermediateBlockModel(for identifier: Identifier) throws -> IntermediateBlockModel {
    if let blockModel = intermediateCache[identifier] {
      return blockModel
    }
    
    let blockModelJSON = try assetManager.getBlockModelJSON(for: identifier)
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
        let rescale = rotationJSON?.getBool(forKey: "rescale") ?? false
        
        _ = elementJSON.getBool(forKey: "shade")
        
        var faces: [FaceDirection: IntermediateBlockModelElementFace] = [:]
        let facesDict = (elementJSON.getJSON(forKey: "faces")?.dict as? [String: [String: Any]]) ?? [:]
        for (faceName, faceDict) in facesDict {
          if let direction = FaceDirection(rawValue: faceName) {
            let faceJSON = JSON(dict: faceDict)
            
            let uv = faceJSON.getArray(forKey: "uv") as? [Float] ?? [0, 0, 16, 16]
            let cullface = faceJSON.getString(forKey: "cullface")
            let rotation = faceJSON.getInt(forKey: "rotation") ?? 0
            let tintIndex = faceJSON.getInt(forKey: "tintIndex")
            
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
                  cullface: cullface != nil ? FaceDirection(rawValue: cullface!) : nil,
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
          
          // IMPLEMENT: rescale
//          if rescale {
//            modelMatrix *= MatrixUtil.scalingMatrix(5, 1, 5)
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
}
