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
  case failedToEnumerateBlockModels
  case failedToReadJSON
  case failedToParseJSON
  case invalidIdentifier
  case noFileForParent
  case noSuchBlockModel
  case invalidDisplayTag
}

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

// TODO: block model error handling
class BlockModelManager {
  var assetManager: AssetManager
  
  var identifierToBlockModel: [Identifier: MojangBlockModel] = [:]
  
  init(assetManager: AssetManager) {
    self.assetManager = assetManager
  }
  
  func loadBlockModels() throws {
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
        identifierToBlockModel[identifier] = blockModel
      } catch {
        throw error
      }
    }
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
    guard let blockModel = identifierToBlockModel[identifier] else {
      throw BlockModelError.noSuchBlockModel
    }
    return blockModel
  }
}
