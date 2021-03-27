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
  var fullFaces: Set<FaceDirection>
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
          var xRot: Int = 0
          var yRot: Int = 0
          var zRot: Int = 0
          var uvlock: Bool = false
          
          if let render = stateJSON.getJSON(forKey: "render") {
            modelIdentifierString = render.getString(forKey: "model")
            xRot = render.getInt(forKey: "x") ?? 0
            yRot = render.getInt(forKey: "y") ?? 0
            zRot = render.getInt(forKey: "z") ?? 0
            uvlock = render.getBool(forKey: "uvlock") ?? false
          } else if let render = stateJSON.getArray(forKey: "render") as? [[String: Any]] {
            // IMPLEMENT: handling multiple states for one state id
            let json = JSON(dict: render[0])
            modelIdentifierString = json.getString(forKey: "model")
            xRot = json.getInt(forKey: "x") ?? 0
            yRot = json.getInt(forKey: "y") ?? 0
            zRot = json.getInt(forKey: "z") ?? 0
            uvlock = json.getBool(forKey: "uvlock") ?? false
          }
          
          let rotationMatrix = MatrixUtil.rotationMatrix(x: Float(xRot) / 180 * Float.pi)
            * MatrixUtil.rotationMatrix(y: Float(yRot) / 180 * Float.pi)
            * MatrixUtil.rotationMatrix(z: Float(zRot) / 180 * Float.pi)
          
          let modelMatrix = MatrixUtil.translationMatrix([-0.5, -0.5, -0.5]) * rotationMatrix * MatrixUtil.translationMatrix([0.5, 0.5, 0.5])
          
          if modelIdentifierString != nil {
            do {
              let modelIdentifier = try Identifier(modelIdentifierString!)
              var blockModel = try loadBlockModel(for: modelIdentifier)
              
              if modelMatrix != matrix_float4x4(1) {
                for (index, var element) in blockModel.elements.enumerated() {
                  element.modelMatrix *= modelMatrix
                  for (direction, var face) in element.faces {
                    if var cullface = face.cullface {
                      let vector = simd_float4(cullface.toVector(), 1) * rotationMatrix
                      cullface = FaceDirection.fromVector(vector: simd_make_float3(vector))
                      face.cullface = cullface
                    }
                    
                    if uvlock {
                      switch direction.axis {
                        case .x:
                          face.rotation += xRot
                        case .y:
                          face.rotation += yRot
                        case .z:
                          face.rotation += zRot
                      }
                    }
                    
                    face.rotation = face.rotation % 360
                    
                    element.faces[direction] = face
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
  }
  
  func loadBlockModel(for identifier: Identifier) throws -> BlockModel {
    // IMPLEMENT: block model rotations
    let intermediate = try loadIntermediateBlockModel(for: identifier)
    
    var fullFaces = Set<FaceDirection>()
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
      let modelMatrix = intermediateElement.modelMatrix
      let element = BlockModelElement(modelMatrix: modelMatrix, faces: faces)
      elements.append(element)
      
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
        let _ = rotationJSON?.getBool(forKey: "rescale") ?? false
        
        _ = elementJSON.getBool(forKey: "shade")
        
        var faces: [FaceDirection: IntermediateBlockModelElementFace] = [:]
        let facesDict = (elementJSON.getJSON(forKey: "faces")?.dict as? [String: [String: Any]]) ?? [:]
        for (faceName, faceDict) in facesDict {
          if let direction = FaceDirection(rawValue: faceName) {
            let faceJSON = JSON(dict: faceDict)
            
            let uv = faceJSON.getArray(forKey: "uv") as? [Float] ?? [0, 0, 16, 16]
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
