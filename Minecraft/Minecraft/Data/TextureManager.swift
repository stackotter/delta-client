//
//  TextureManager.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/3/21.
//

import Foundation
import MetalKit
import os

enum TextureError: LocalizedError {
  case failedToGetBlockTexturesFolder
  case failedToEnumerateBlockTextures
  case failedToLoadTextures
}

class TextureManager {
  var assetManager: AssetManager
  
  var images: [Identifier: CGImage] = [:]
  var identifierToBlockTextureIndex: [Identifier: Int] = [:]
  
  init(assetManager: AssetManager) {
    self.assetManager = assetManager
  }
  
  func loadBlockTextures() throws {
    guard let texturesFolder = assetManager.getBlockTexturesFolder() else {
      throw TextureError.failedToGetBlockTexturesFolder
    }
    
    guard let textureDirectoryContents = try? FileManager.default.contentsOfDirectory(at: texturesFolder, includingPropertiesForKeys: nil, options: []) else {
      throw TextureError.failedToEnumerateBlockTextures
    }
    
    var textureFileNames: [URL] = []
    for fileName in textureDirectoryContents {
      if fileName.pathExtension == "png" {
        textureFileNames.append(fileName)
      }
    }
    
    for filename in textureFileNames {
      let textureName = filename.deletingPathExtension().lastPathComponent
      let identifier = Identifier(name: "block/\(textureName)")
      
      if let dataProvider = CGDataProvider(url: filename as CFURL) {
        if let cgImage = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) {
          if cgImage.width == 16 && cgImage.height == 16 {
            images[identifier] = cgImage
          }
        } else {
          Logger.warning("failed to load '\(textureName).png' as cgimage")
        }
      } else {
        Logger.warning("failed to create cgdataprovider for '\(textureName).png'")
      }
    }
  }
  
  func createArrayTexture(metalDevice: MTLDevice) -> MTLTexture {
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.textureType = .type2DArray
    textureDescriptor.arrayLength = images.count
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.width = 16
    textureDescriptor.height = 16
    
    let textureArray = metalDevice.makeTexture(descriptor: textureDescriptor)!
    
    let bitsPerComponent = 8
    let bytesPerPixel = 4
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = UInt32(Int(kColorSyncAlphaPremultipliedFirst.rawValue) | kColorSyncByteOrder32Little)
    
    for (index, (identifier, image)) in images.enumerated() {
      if index == 0 { // logs what texture is currently being used to render chunk
        Logger.debug("at index 0: \(identifier)")
      }
      let width = image.width
      let height = image.height
      let bytesPerRow = bytesPerPixel*16
      
      let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo
      )!
      
      let rect = CGRect(x: 0, y: 0, width: width, height: height)
      context.clear(rect)
      context.draw(image, in: rect)
      context.flush()
      
      let bytes = context.data!
      
      textureArray.replace(
        region: MTLRegion(
          origin: MTLOrigin(x: 0, y: 0, z: 0),
          size: MTLSize(width: width, height: height, depth: 1)
        ),
        mipmapLevel: 0,
        slice: index,
        withBytes: bytes,
        bytesPerRow: bytesPerRow,
        bytesPerImage: bytesPerRow*height
      )
      identifierToBlockTextureIndex[identifier] = index
    }
    
    return textureArray
  }
}
