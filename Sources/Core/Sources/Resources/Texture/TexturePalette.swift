import Foundation
import MetalKit

public struct TexturePalette {
  /// The width of the textures in this palette. The heights will be multiples of this number.
  public var width: Int
  
  /// An index for `textures`.
  private var identifierToIndex: [Identifier: Int]
  /// The palette's textures, indexed by `identifierToIndex`.
  public var textures: [Texture]
  
  // MARK: Init
  
  /// Creates an empty texture palette.
  public init() {
    width = 0
    identifierToIndex = [:]
    textures = []
  }
  
  /// Creates a texture palette containing the given textures which all share the same specified width.
  public init(_ textures: [(Identifier, Texture)], width: Int) {
    self.width = width
    identifierToIndex = [:]
    self.textures = []
    
    for (index, (identifier, texture)) in textures.enumerated() {
      identifierToIndex[identifier] = index
      self.textures.append(texture)
    }
  }
  
  // MARK: Access
  
  /// Returns the index of the texture referred to by the given identifier if it exists.
  public func textureIndex(for identifier: Identifier) -> Int? {
    return identifierToIndex[identifier]
  }
  
  /// Returns the texture referred to by the given identifier if it exists.
  public func texture(for identifier: Identifier) -> Texture? {
    if let index = textureIndex(for: identifier) {
      return textures[index]
    } else {
      return nil
    }
  }
  
  // MARK: Loading
  
  /// Loads the texture palette present in the given directory. `type` refers to the part before the slash in the name. Like `block` in `minecraft:block/dirt`.
  public static func load(from directory: URL, inNamespace namespace: String, withType type: String) throws -> TexturePalette {
    let files: [URL]
    do {
      files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
    } catch {
      throw ResourcePackError.failedToEnumerateTextures(error)
    }
    
    // Textures are loaded in two phases so that we know what the widest texture is before we do work scaling them all to the right widths.
    
    // Load the images
    var maxWidth = 0 // The width of the widest texture in the palette
    var images: [(Identifier, CGImage)] = []
    for file in files where file.pathExtension == "png" {
      let name = file.deletingPathExtension().lastPathComponent
      let identifier = Identifier(namespace: namespace, name: "\(type)/\(name)")
      
      let image = try CGImage(pngFile: file)
      
      if image.width > maxWidth {
        maxWidth = image.width
      }
      
      images.append((identifier, image))
    }
    
    // Convert the images to textures
    var textures: [(Identifier, Texture)] = []
    for (identifier, image) in images {
      let name = identifier.name.split(separator: "/")[1]
      let animationMetadataFile = directory.appendingPathComponent("\(name).png.mcmeta")
      do {
        // Hardcode leaves as opaque for performance reasons
        let hardcodeOpaque = identifier.name.hasSuffix("leaves")
        
        var texture = try Texture(
          image: image,
          type: hardcodeOpaque ? .opaque : nil,
          scaledToWidth: maxWidth,
          checkDimensions: true)
        
        if texture.type != .opaque {
          // Change the color of transparent pixels to make mipmaps look more natural
          texture.fixTransparentPixels()
        }
        
        if FileManager.default.fileExists(atPath: animationMetadataFile.path) {
          try texture.setAnimation(file: animationMetadataFile)
        }
        
        textures.append((identifier, texture))
      } catch {
        throw ResourcePackError.failedToLoadTexture(identifier, error)
      }
    }
    
    return TexturePalette(textures, width: maxWidth)
  }
  
  // MARK: Metal
  
  /// Returns a metal texture array on the given device, containing the first frame of each texture.
  public func createTextureArray(device: MTLDevice, animationState: TexturePaletteAnimationState, commandQueue: MTLCommandQueue) throws -> MTLTexture {
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.width = width
    textureDescriptor.height = width
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.textureType = .type2DArray
    textureDescriptor.arrayLength = textures.count
    textureDescriptor.storageMode = (device.hasUnifiedMemory) ? .shared : .managed
    textureDescriptor.mipmapLevelCount = 1 + Int(log2(Double(width)).rounded(.down))
//    textureDescriptor.resourceOptions = [.]
    
    guard let arrayTexture = device.makeTexture(descriptor: textureDescriptor) else {
      throw RenderError.failedToCreateTextureArray
    }
    
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bytesPerFrame = bytesPerRow * width
    
    for (index, texture) in textures.enumerated() {
      let offset = animationState.frame(forTextureAt: index) * bytesPerFrame
      arrayTexture.replace(
        region: MTLRegion(
          origin: MTLOrigin(x: 0, y: 0, z: 0),
          size: MTLSize(width: width, height: width, depth: 1)),
        mipmapLevel: 0,
        slice: index,
        withBytes: texture.bytes.withUnsafeBytes({ $0.baseAddress!.advanced(by: offset) }),
        bytesPerRow: bytesPerRow,
        bytesPerImage: bytesPerFrame)
    }
    
    if let commandBuffer = commandQueue.makeCommandBuffer() {
      if let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder() {
        blitCommandEncoder.generateMipmaps(for: arrayTexture)
        blitCommandEncoder.endEncoding()
        commandBuffer.commit()
      } else {
        log.error("Failed to create blit command encoder to create mipmaps")
      }
    } else {
      log.error("Failed to create command buffer to create mipmaps")
    }
    
    return arrayTexture
  }
  
  public func updateArrayTexture(arrayTexture: MTLTexture, device: MTLDevice, animationState: TexturePaletteAnimationState, updatedTextures: [Int], commandQueue: MTLCommandQueue) {
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bytesPerFrame = bytesPerRow * width
    
    for index in updatedTextures {
      let texture = textures[index]
      let offset = animationState.frame(forTextureAt: index) * bytesPerFrame
      arrayTexture.replace(
        region: MTLRegion(
          origin: MTLOrigin(x: 0, y: 0, z: 0),
          size: MTLSize(width: width, height: width, depth: 1)),
        mipmapLevel: 0,
        slice: index,
        withBytes: texture.bytes.withUnsafeBytes({ $0.baseAddress!.advanced(by: offset) }),
        bytesPerRow: bytesPerRow,
        bytesPerImage: bytesPerFrame)
    }
    
    // TODO: only regenerate necessary mipmaps
    if let commandBuffer = commandQueue.makeCommandBuffer() {
      if let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder() {
        blitCommandEncoder.generateMipmaps(for: arrayTexture)
        blitCommandEncoder.endEncoding()
        commandBuffer.commit()
      } else {
        log.error("Failed to create blit command encoder to create mipmaps")
      }
    } else {
      log.error("Failed to create command buffer to create mipmaps")
    }
  }
}
