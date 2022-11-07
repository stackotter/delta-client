import Foundation
import CoreGraphics

/// A palette containing textures that can be animated. All of the textures must be the same size or
/// multiples of 2 of eachother. Textures are assumed to be square.
public final class TexturePalette { // TODO: Currently a class to avoid copies, maybe use a `Box` or `Ref` type instead.
  /// The palette's textures, indexed by ``identifierToIndex``.
  public var textures: [Texture]

  /// The width of the textures in this palette. The heights will be multiples of this number.
  public var width: Int

  /// An index for ``textures``.
  public var identifierToIndex: [Identifier: Int]

  // MARK: Init

  /// Creates an empty texture palette.
  public init() {
    textures = []
    width = 0
    identifierToIndex = [:]
  }

  /// Creates a texture palette containing the given textures which all share the same specified width.
  public init(_ textures: [(Identifier, Texture)], width: Int) {
    self.textures = []
    self.width = width
    identifierToIndex = [:]

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

  /// Loads the texture palette present in the given directory. `type` refers to the part before the
  /// slash in the name. Like `block` in `minecraft:block/dirt`.
  public static func load(
    from directory: URL,
    inNamespace namespace: String,
    withType type: String
  ) throws -> TexturePalette {
    let files: [URL]
    do {
      files = try FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: []
      )
    } catch {
      throw ResourcePackError.failedToEnumerateTextures(error)
    }

    // Textures are loaded in two phases so that we know what the widest texture is before we do
    // work scaling them all to the right widths.

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
          checkDimensions: true
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
        throw ResourcePackError.failedToLoadTexture(identifier, error)
      }
    }

    return TexturePalette(textures, width: maxWidth)
  }
}
