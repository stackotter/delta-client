import Foundation
import SwiftImage

/// A palette containing textures that can be animated. All of the textures must be the same size or
/// multiples of 2 of eachother. Textures are assumed to be square.
public struct TexturePalette {
  /// The palette's textures, indexed by ``identifierToIndex``.
  public var textures: [Texture]

  /// The width of the textures in this palette.
  public var width: Int
  /// The height of a single texture frame in this palette. The heights of the textures will be multiples of this number.
  public var height: Int

  /// An index for ``textures``.
  public var identifierToIndex: [Identifier: Int]

  /// The default animation state for the texture palette. Defaults to the first frame for every
  /// animated texture.
  public var defaultAnimationState: AnimationState {
    return AnimationState(for: textures)
  }

  // MARK: Init

  /// Creates an empty texture palette.
  public init() {
    textures = []
    width = 0
    height = 0
    identifierToIndex = [:]
  }

  /// Creates a texture palette containing the given textures which all share the same specified width.
  public init(_ textures: [(Identifier, Texture)], width: Int, height: Int) {
    self.textures = []
    self.width = width
    self.height = height
    identifierToIndex = [:]

    for (index, (identifier, texture)) in textures.enumerated() {
      identifierToIndex[identifier] = index
      self.textures.append(texture)
    }
  }

  /// Creates a texture palette by providing all of its properties. Used internally for caching, and
  /// not very useful outside of that usecase.
  init(textures: [Texture], width: Int, height: Int, identifierToIndex: [Identifier: Int]) {
    self.textures = textures
    self.width = width
    self.height = height
    self.identifierToIndex = identifierToIndex
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

  /// Loads the texture palette present in the given directory. `type` refers to the part before the
  /// slash in the name. Like `block` in `minecraft:block/dirt`.
  /// - Parameters:
  ///   - recursive: If recursive, textures will also be loaded from
  ///     subdirectories of the given directory.
  ///   - isAnimated: If `true`, all textures are resized to the same width and their height must be a multiple
  ///     of their width. Also, the palette height (frame height) will be set to the palette width.
  ///     Used for palettes like the block and item texture palettes.
  public static func load(
    from directory: URL,
    inNamespace namespace: String,
    withType type: String,
    recursive: Bool = false,
    isAnimated: Bool = true
  ) throws -> TexturePalette {
    // I hate the remnants of ObjC left in Swift, this is such a stupid file enumeration API
    guard
      let enumerator = FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: [],
        options: recursive ? [] : [.skipsSubdirectoryDescendants]
      )
    else {
      throw ResourcePackError.failedToEnumerateTextures
    }

    let files = enumerator.compactMap { file in
      return file as? URL
    }

    // Textures are loaded in two phases so that we know what the widest texture is before we do
    // work scaling them all to the right widths.

    // Load the images
    var maxWidth = 0 // The width of the widest texture in the palette
    var maxHeight = 0
    var images: [(Identifier, Image<RGBA<UInt8>>)] = []
    for file in files where file.pathExtension == "png" {
      var name = file.deletingPathExtension().path.dropFirst(directory.path.count)
      if name.hasPrefix("/") {
        name = name.dropFirst()
      }
      let identifier = Identifier(namespace: namespace, name: "\(type)/\(name)")

      let image = try Image<RGBA<UInt8>>(fromPNGFile: file)
      if image.width > maxWidth {
        maxWidth = image.width
      }
      if image.height > maxHeight {
        maxHeight = image.height
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

        // Only check dimensions if we need to resize
        var texture = try Texture(
          image: image,
          type: hardcodeOpaque ? .opaque : nil,
          scaledToWidth: isAnimated ? maxWidth : image.width,
          checkDimensions: isAnimated
        )

        if texture.type == .opaque {
          texture.setAlpha(255)
        } else {
          // Change the color of transparent pixels to make mipmaps look more natural
          texture.fixTransparentPixels()
        }

        if FileManager.default.fileExists(atPath: animationMetadataFile.path) {
          try texture.setAnimation(file: animationMetadataFile)
        }

        textures.append((identifier, texture))
      } catch {
        throw ResourcePackError.failedToLoadTexture(identifier).becauseOf(error)
      }
    }

    return TexturePalette(textures, width: maxWidth, height: isAnimated ? maxWidth : maxHeight)
  }
}
