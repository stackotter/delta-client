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
  case missingBlockModelFolder
  case missingBlockStatesFolder
  case failedToEnumerateBlockModels
  case failedToReadJSON
  case failedToParseJSON
  case invalidIdentifier
  case noFileForParent
  case noSuchBlockModel
  case invalidDisplayTag
  case invalidBlockPalette
  case invalidBlockIdentifier
  case invalidBlockStateJSON
  case nonExistentPropertyCombination
  case blockModelMissingParent
  case invalidPositionFromJSON
  case invalidRotationAxis
  case invalidAngle
  case invalidFaceDirection
  case invalidUV
  case invalidCullFace
}

// the format of block models basically as mojang gives it in the json
struct MojangBlockModelElementRotation {
  var origin: [Float]
  var axis: String
  var angle: Float
  var rescale: Bool
}

struct MojangBlockModelElementFace {
  var uv: [Float]
  var texture: String
  var cullface: String
  var rotation: Int
  var tintIndex: Int?
}

struct MojangBlockModelElement {
  var from: [Float]
  var to: [Float]
  var rotation: MojangBlockModelElementRotation
  var shade: Bool
  var faces: [String: MojangBlockModelElementFace]
}

struct MojangBlockModelDisplayLocation {
  var rotation: [Double]?
  var translation: [Double]?
  var scale: [Double]?
}

// https://minecraft.gamepedia.com/Model#Block_models
struct MojangBlockModel {
  var parent: Identifier?
  var ambientOcclusion: Bool
  var displayLocations: [String: MojangBlockModelDisplayLocation]
  var textures: [String: String]
  var elements: [MojangBlockModelElement]
}

enum FaceDirection: String {
  case down = "down"
  case up = "up"
  case north = "north"
  case south = "south"
  case west = "west"
  case east = "east"
}

// an intermediate block model used before global palette is loaded
struct IntermediateBlockModelElementFace {
  var textureCoordinates: (simd_float2, simd_float2)
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
  var textureCoordinates: (simd_float2, simd_float2)
  var textureIndex: Int // the index of the texture to use in the block texture buffer
  var cullface: FaceDirection?
  var tintIndex: Int?
}

struct BlockModelElement {
  var modelMatrix: simd_float4x4
  var faces: [FaceDirection: BlockModelElementFace]
}

struct BlockModel {
  var elements: [BlockModelElement]
}


enum Axis: String {
  case x = "x"
  case y = "y"
  case z = "z"
}


// TODO: think of a better name for BlockModelManager
class BlockModelManager {
  var assetManager: AssetManager
  var textureManager: TextureManager
  
  var identifierToMojangBlockModel: [Identifier: MojangBlockModel] = [:]
  var identifierToIntermediateBlockModel: [Identifier: IntermediateBlockModel] = [:]
  
  var blockModelPalette: [Int: BlockModel] = [:]
  
  init(assetManager: AssetManager, textureManager: TextureManager) {
    self.assetManager = assetManager
    self.textureManager = textureManager
  }
  
  func loadBlockModels() throws {
    // load the block models into the structs prefixed with Mojang (to make the data easier to manipulate)
    guard let blockModelFolder = assetManager.getBlockModelFolder() else {
      throw BlockModelError.missingBlockModelFolder
    }
    guard let blockModelFiles = try? FileManager.default.contentsOfDirectory(at: blockModelFolder, includingPropertiesForKeys: nil, options: []) else {
      throw BlockModelError.failedToEnumerateBlockModels
    }
    
    for file in blockModelFiles {
      let identifier = identifierFromFileName(file)
      do {
        let blockModel = try loadBlockModel(fileName: file)
        identifierToMojangBlockModel[identifier] = blockModel
      } catch {
        throw error
      }
    }
    
    // convert mojang block models to an intermediate block model structure
    // the actual block models will be generated after the global block palette is loaded
    for (identifier, mojangBlockModel) in identifierToMojangBlockModel {
      do {
        let intermediateBlockModel = try flattenMojangBlockModel(mojangBlockModel, identifier: identifier)
        identifierToIntermediateBlockModel[identifier] = intermediateBlockModel
      } catch {
        Logger.error("failed to flatten mojang block model with error: \(error)")
      }
    }
  }
  
  func flattenMojangBlockModel(_ mojangBlockModel: MojangBlockModel, identifier: Identifier) throws -> IntermediateBlockModel {
    var parentBlockModel: IntermediateBlockModel? = nil
    if let parentIdentifier = mojangBlockModel.parent {
      if let parent = identifierToIntermediateBlockModel[parentIdentifier] {
        parentBlockModel = parent
      } else {
        guard let parentMojangBlockModel = identifierToMojangBlockModel[parentIdentifier] else {
          Logger.error("block model missing parent '\(parentIdentifier)'")
          throw BlockModelError.blockModelMissingParent
        }
        do {
          parentBlockModel = try flattenMojangBlockModel(parentMojangBlockModel, identifier: parentIdentifier)
        } catch {
          Logger.error("failed to flatten parent '\(parentIdentifier)'")
        }
      }
    }
    
    var elements: [IntermediateBlockModelElement] = []
    
    // get elements
    if mojangBlockModel.elements.count != 0 { // TODO: check the json format when reading json, not here
      // flatten elements
      for mojangElement in mojangBlockModel.elements {
        guard mojangElement.from.count == 3 && mojangElement.to.count == 3 && mojangElement.rotation.origin.count == 3 else {
          Logger.error("invalid number of elements in position, from: \(mojangElement.from), to: \(mojangElement.to), origin: \(mojangElement.rotation.origin)")
          throw BlockModelError.invalidPositionFromJSON
        }
        let from = simd_float3(mojangElement.from)/16.0
        let to = simd_float3(mojangElement.to)/16.0
        
        let rotationOrigin = simd_float3(mojangElement.rotation.origin)
        guard let axis = Axis(rawValue: mojangElement.rotation.axis) else {
          Logger.error("invalid rotation axis in block model: \(mojangElement.rotation.axis)")
          throw BlockModelError.invalidRotationAxis
        }
        let angle = mojangElement.rotation.angle
        let acceptableAngles: [Float] = [-45, -22.5, 0, 22.5, 45]
        guard acceptableAngles.contains(angle) else {
          Logger.error("block model contains invalid angle: \(angle)")
          throw BlockModelError.invalidAngle
        }
        let rescale = mojangElement.rotation.rescale
        
        var modelMatrix = MatrixUtil.translationMatrix(from)
        modelMatrix *= MatrixUtil.scalingMatrix(to.x, to.y, to.z) // TODO: make scaling matrix function that accepts simd_float3 as argument
        modelMatrix *= MatrixUtil.translationMatrix(-rotationOrigin)
        switch axis {
          case .x:
            modelMatrix *= MatrixUtil.rotationMatrix(x: angle)
          case .y:
            modelMatrix *= MatrixUtil.rotationMatrix(y: angle)
          case .z:
            modelMatrix *= MatrixUtil.rotationMatrix(z: angle)
        }
        modelMatrix *= MatrixUtil.translationMatrix(rotationOrigin)
        // TODO: implement rescale
        
        var faces: [FaceDirection: IntermediateBlockModelElementFace] = [:]
        for (directionString, mojangFace) in mojangElement.faces {
          guard let direction = FaceDirection(rawValue: directionString) else {
            Logger.error("block model element contains invalid face direction: \(directionString)")
            throw BlockModelError.invalidFaceDirection
          }
          let cullface = FaceDirection(rawValue: mojangFace.cullface)
          guard mojangFace.uv.count == 4 else {
            Logger.error("block model uv contains invalid number of elements: \(mojangFace.uv)")
            throw BlockModelError.invalidUV
          }
          let textureCoordinates = (
            simd_float2(mojangFace.uv[0], mojangFace.uv[1]),
            simd_float2(mojangFace.uv[2], mojangFace.uv[3])
          )
          
          let face = IntermediateBlockModelElementFace(
            textureCoordinates: textureCoordinates,
            textureVariable: mojangFace.texture,
            cullface: cullface,
            rotation: mojangFace.rotation,
            tintIndex: mojangFace.tintIndex
          )
          
          faces[direction] = face
        }
        
        let element = IntermediateBlockModelElement(
          modelMatrix: modelMatrix,
          faces: faces
        )
        
        elements.append(element)
      }
    } else {
      elements = parentBlockModel?.elements ?? []
    }
    
    // substitute texture variables
    for (index, var element) in elements.enumerated() {
      for (direction, var face) in element.faces {
        var texture: String
        if face.textureVariable.starts(with: "#") {
          texture = mojangBlockModel.textures[String(face.textureVariable.dropFirst())] ?? face.textureVariable
        } else {
          texture = face.textureVariable
        }
        face.textureVariable = texture
        element.faces[direction] = face
      }
      elements[index] = element
    }
    
    let blockModel = IntermediateBlockModel(
      elements: elements
    )
    return blockModel
  }
  
  func loadGlobalPalette() throws {
    try loadBlockModels()
    
    guard let blockStatesFolder = assetManager.getBlockStatesFolder() else {
      throw BlockModelError.missingBlockStatesFolder
    }
    let blockPalettePath = assetManager.storageManager.getBundledResourceByName("blocks", fileExtension: ".json")!
    guard let blockPaletteDict = try? JSON.fromURL(blockPalettePath).dict as? [String: [String: Any]] else {
      Logger.error("failed to load block palette from bundle")
      throw BlockModelError.invalidBlockPalette
    }
    for (identifierString, blockDict) in blockPaletteDict {
      let paletteBlockJSON = JSON(dict: blockDict)
      guard let identifier = try? Identifier(identifierString) else {
        throw BlockModelError.invalidBlockIdentifier
      }
      guard let paletteStatesArray = paletteBlockJSON.getArray(forKey: "states") as? [[String: Any]] else {
        throw BlockModelError.invalidBlockPalette
      }
//      let palettePropertiesJSON = paletteBlockJSON.getJSON(forKey: "properties")
      
      let blockStateFile = blockStatesFolder.appendingPathComponent("\(identifier.name).json")
      guard let blockStateJSON = try? JSON.fromURL(blockStateFile) else {
        Logger.error("failed to load block state json: invalid json in file '\(identifier.name).json'")
        throw BlockModelError.invalidBlockStateJSON
      }
      
      // loop through all states for block (and skip multiparts)
      if let variants = blockStateJSON.getJSON(forKey: "variants") {
        if let variant = variants.getJSON(forKey: "") { // all states for block use one variant
          guard let variantString = variant.getString(forKey: "model") else {
            Logger.error("failed to load block state json: variant '' doesn't specify a model on '\(identifier.name)'")
            throw BlockModelError.invalidBlockStateJSON
          }
          guard let variantBlockModelIdentifier = try? Identifier(variantString) else {
            throw BlockModelError.invalidIdentifier
          }
          for paletteStateDict in paletteStatesArray {
            let paletteStateJSON = JSON(dict: paletteStateDict)
            guard let stateId = paletteStateJSON.getInt(forKey: "id") else {
              Logger.error("failed to load block palette: '\(identifier.name)' contains a state without an id")
              throw BlockModelError.invalidBlockPalette
            }
            if let intermediateBlockModel = identifierToIntermediateBlockModel[variantBlockModelIdentifier] {
              let blockModel = intermediateToBlockModel(intermediateBlockModel)
              blockModelPalette[stateId] = blockModel
            } else {
              Logger.error("no block model '\(variantBlockModelIdentifier)' found for variant '' of block state '\(identifier)' with id \(stateId)")
            }
          }
        } else { // a different variant for each state
          for paletteStateDict in paletteStatesArray {
            let paletteStateJSON = JSON(dict: paletteStateDict)
            guard let stateId = paletteStateJSON.getInt(forKey: "id") else {
              Logger.error("failed to load block palette: '\(identifier.name)' contains a state without an id")
              throw BlockModelError.invalidBlockPalette
            }
            
            if let properties = paletteStateJSON.getJSON(forKey: "properties")?.dict as? [String: String] { // TODO: variant rotations
              let propertyNames = properties.keys.sorted()
              var variantKeyParts: [String] = []
              for propertyName in propertyNames {
                variantKeyParts.append("\(propertyName)=\(properties[propertyName]!)")
              }
              let variantKey = variantKeyParts.joined(separator: ",")
              if let variant = variants.getJSON(forKey: variantKey) {
                guard let variantModel = variant.getString(forKey: "model") else {
                  Logger.error("failed to load block state json: variant '\(variantKey)' doesn't specify a model on '\(identifier.name)'")
                  throw BlockModelError.invalidBlockStateJSON
                }
                guard let variantModelIdentifier = try? Identifier(variantModel) else {
                  Logger.error("variant's block model identifier is invalid, '\(variantModel)'")
                  throw BlockModelError.invalidIdentifier
                }
                if let intermediateBlockModel = identifierToIntermediateBlockModel[variantModelIdentifier] {
                  let blockModel = intermediateToBlockModel(intermediateBlockModel)
                  blockModelPalette[stateId] = blockModel
                }
              } else {
                // at the moment block states that we can't handle are just passed
//                Logger.debug("no variant for '\(variantKey)' on '\(identifier.name)'")
//                throw BlockModelError.nonExistentPropertyCombination
              }
            } else {
              // handle blocks with multiple variants under the same name (randomly choose one each time based on where the block is)
            }
          }
        }
      }
      if identifier.name == "birch_log" {
        Logger.debug("birch log up texture index: \(blockModelPalette[80]?.elements[0].faces[.up])")
        Logger.debug("birch log north texture index: \(blockModelPalette[80]?.elements[0].faces[.north])")
      }
    }
  }
  
  func intermediateToBlockModel(_ intermediateBlockModel: IntermediateBlockModel) -> BlockModel {
    var elements: [BlockModelElement] = []
    for intermediateElement in intermediateBlockModel.elements {
      let modelMatrix = intermediateElement.modelMatrix
      // TODO: implement block rotations
      
      var faces: [FaceDirection: BlockModelElementFace] = [:]
      for (direction, intermediateFace) in intermediateElement.faces {
        let textureName = intermediateFace.textureVariable
        if let textureIdentifier = try? Identifier(textureName) {
          if let textureIndex = textureManager.identifierToBlockTextureIndex[textureIdentifier] {
            let face = BlockModelElementFace(
              textureCoordinates: intermediateFace.textureCoordinates,
              textureIndex: textureIndex,
              cullface: intermediateFace.cullface,
              tintIndex: intermediateFace.tintIndex
            )
            faces[direction] = face
          } else {
            // currently this is reached for animated textures (because the textures are bigger than 16x16
          }
        } else {
          Logger.error("block model's texture is not a valid identifier: '\(textureName)'")
        }
      }
      let element = BlockModelElement(
        modelMatrix: modelMatrix,
        faces: faces
      )
      elements.append(element)
    }
    let blockModel = BlockModel(elements: elements)
    return blockModel
  }
  
  func loadBlockModel(fileName: URL) throws -> MojangBlockModel {
    guard let blockModelJSON = try? JSON.fromURL(fileName) else {
      throw BlockModelError.failedToReadJSON
    }
    
    do {
      var parent: Identifier? = nil
      if let parentName = blockModelJSON.getString(forKey: "parent") {
        guard let parentIdentifier = try? Identifier(parentName) else {
          throw BlockModelError.invalidIdentifier
        }
        parent = parentIdentifier
      }
      
      // actually read the block model
      let ambientOcclusion = blockModelJSON.getBool(forKey: "ambientocclusion") ?? true
      var displayLocations: [String: MojangBlockModelDisplayLocation] = [:]
      if let displayJSON = blockModelJSON.getJSON(forKey: "display")?.dict as? [String: [String: Any]] {
        for (location, transformations) in displayJSON {
          let transformationsJSON = JSON(dict: transformations)
          let rotation = transformationsJSON.getArray(forKey: "rotation") as? [Double]
          let translation = transformationsJSON.getArray(forKey: "translation") as? [Double]
          let scale = transformationsJSON.getArray(forKey: "scale") as? [Double]
          displayLocations[location] = MojangBlockModelDisplayLocation(rotation: rotation, translation: translation, scale: scale)
        }
      }
      let textureVariables: [String: String] = (blockModelJSON.getAny(forKey: "textures") as? [String: String]) ?? [:]
      
      var elements: [MojangBlockModelElement] = []
      if let elementsArray = blockModelJSON.getArray(forKey: "elements") as? [[String: Any]] {
        for elementDict in elementsArray {
          let elementJSON = JSON(dict: elementDict)
          let from = elementJSON.getArray(forKey: "from") as? [Float]
          let to = elementJSON.getArray(forKey: "to") as? [Float]
          
          let rotationJSON = elementJSON.getJSON(forKey: "rotation")
          let origin = rotationJSON?.getArray(forKey: "origin") as? [Float]
          let axis = rotationJSON?.getString(forKey: "axis")
          let angle = rotationJSON?.getFloat(forKey: "angle")
          let rescale = rotationJSON?.getBool(forKey: "rescale")
          let rotation = MojangBlockModelElementRotation( // TODO: reconsider these default values
            origin: origin ?? [0, 0 ,0],
            axis: axis ?? "x",
            angle: angle != nil ? Float(angle!) : 0,
            rescale: rescale ?? false
          )
          
          let shade = elementJSON.getBool(forKey: "shade")
          
          var faces: [String: MojangBlockModelElementFace] = [:]
          if let facesDict = elementJSON.getJSON(forKey: "faces")?.dict as? [String: [String: Any]] {
            for (faceName, faceDict) in facesDict {
              let faceJSON = JSON(dict: faceDict)
              let uv = faceJSON.getArray(forKey: "uv") as? [Float]
              let texture = faceJSON.getString(forKey: "texture")
              let cullface = faceJSON.getString(forKey: "cullface")
              let faceRotation = faceJSON.getInt(forKey: "rotation")
              let tintIndex = faceJSON.getInt(forKey: "tintindex")
              
              let face = MojangBlockModelElementFace( // TODO: reconsider block model face defaults and error handling
                uv: uv ?? [0, 0, 0, 0],
                texture: texture ?? "",
                cullface: cullface ?? "",
                rotation: faceRotation ?? 0,
                tintIndex: tintIndex
              )
              faces[faceName] = face
            }
          }
          
          let element = MojangBlockModelElement(
            from: from ?? [0, 0, 0],
            to: to ?? [16, 16, 16],
            rotation: rotation,
            shade: shade ?? true,
            faces: faces
          )
          
          elements.append(element)
        }
      }
      
      let blockModel = MojangBlockModel(
        parent: parent,
        ambientOcclusion: ambientOcclusion,
        displayLocations: displayLocations,
        textures: textureVariables,
        elements: elements
      )
      
      return blockModel
    } catch {
      Logger.error("failed to load block model: \(error)")
      throw BlockModelError.failedToParseJSON
    }
  }
  
  func identifierFromFileName(_ fileName: URL) -> Identifier {
    let blockModelName = fileName.deletingPathExtension().lastPathComponent
    let identifier = Identifier(name: "block/\(blockModelName)")
    return identifier
  }
  
  func blockModelForIdentifier(_ identifier: Identifier) throws -> MojangBlockModel {
    guard let blockModel = identifierToMojangBlockModel[identifier] else {
      throw BlockModelError.noSuchBlockModel
    }
    return blockModel
  }
}
