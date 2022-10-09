import Foundation
import MetalKit

/// An error related to fonts from resource packs.
enum FontError: LocalizedError {
  case failedToGetArrayTextureWidth
  case failedToGetArrayTextureHeight
  case failedToCreateArrayTexture
  case emptyFont
  
  var errorDescription: String? {
    switch self {
      case .failedToGetArrayTextureWidth:
        return "Failed to get array texture width."
      case .failedToGetArrayTextureHeight:
        return "Failed to get array texture height."
      case .failedToCreateArrayTexture:
        return "Failed to create array texture."
      case .emptyFont:
        return "Empty font."
    }
  }
}

/// A font from a resource pack that can be used when rendering text.
public struct Font {
  /// The default character width.
  public static var defaultCharacterWidth = 8
  /// The default character height.
  public static var defaultCharacterHeight = 8

  /// The characters present in this font and the descriptors used to render them.
  public var characters: [Character: CharacterDescriptor]
  /// The ascii characters present in this font, indexed by ascii value. Used to avoid dictionary as
  /// much as possible in performance critical rendering code.
  public var asciiCharacters: [CharacterDescriptor?]
  /// The atlas texture that make up the font.
  public var textures: [Texture]

  /// Creates an empty font.
  public init(characters: [Character: CharacterDescriptor] = [:], textures: [Texture] = []) {
    self.characters = characters
    self.textures = textures

    asciiCharacters = []
    for i in 0..<128 {
      // This is safe because all ascii values are valid unicode scalars
      // swiftlint:disable force_unwrapping
      let character = Character(Unicode.Scalar(i)!)
      // swiftlint:enable force_unwrapping
      asciiCharacters.append(characters[character])
    }
  }

  /// Loads a font from a font manifest and texture directory.
  /// - Parameters:
  ///   - manifestFile: The font's manifest file.
  ///   - textureDirectory: The resource pack's texture directory.
  /// - Throws: An error if texture or manifest loading fails.
  public static func load(from manifestFile: URL, textureDirectory: URL) throws -> Font {
    let manifest = try FontManifest.load(from: manifestFile)
    return try load(from: manifest, textureDirectory: textureDirectory)
  }

  /// Loads a font from a font manifest and texture directory.
  /// - Parameters:
  ///   - manifest: The font's manifest.
  ///   - textureDirectory: The resource pack's texture directory.
  /// - Throws: An error if texture loading fails.
  public static func load(from manifest: FontManifest, textureDirectory: URL) throws -> Font {
    // Load textures and characters from atlases
    var characters: [Character: CharacterDescriptor] = [:]
    var textures: [Texture] = []
    for provider in manifest.providers {
      if case let .bitmap(atlas) = provider {
        // Load texture from file
        let file = textureDirectory.appendingPathComponent(atlas.file.name)
        let texture = try Texture(pngFile: file, type: .transparent)
        textures.append(texture)

        // Calculate bounding boxes of characters in atlas
        let descriptors = Self.descriptors(
          from: atlas,
          texture: texture,
          textureIndex: textures.count - 1
        )

        for (character, descriptor) in descriptors {
          characters[character] = descriptor
        }
      }
    }

    return Font(characters: characters, textures: textures)
  }

  public func descriptor(for character: Character) -> CharacterDescriptor? {
    if let asciiValue = character.asciiValue {
      return asciiCharacters[Int(asciiValue)]
    } else {
      return characters[character]
    }
  }

  /// Creates an array texture containing the font's atlases.
  /// - Parameter device: The device to create the texture with.
  /// - Returns: An array texture containing the textures in ``textures``.
  public func createArrayTexture(
    _ device: MTLDevice
  ) throws -> MTLTexture {
    guard !textures.isEmpty else {
      throw FontError.emptyFont
    }

    // Calculate minimum dimensions to fit all textures.
    guard let width = textures.map({ texture in
      return texture.width
    }).max() else {
      throw FontError.failedToGetArrayTextureWidth
    }

    guard let height = textures.map({ texture in
      return texture.height
    }).max() else {
      throw FontError.failedToGetArrayTextureHeight
    }

    // Create texture descriptor
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.width = width
    textureDescriptor.height = height
    textureDescriptor.arrayLength = textures.count
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.textureType = .type2DArray
    #if os(macOS)
    textureDescriptor.storageMode = .managed
    #elseif os(iOS)
    textureDescriptor.storageMode = .shared
    #else
    #error("Unsupported platform, can't determine storageMode for texture")
    #endif

    guard let arrayTexture = device.makeTexture(descriptor: textureDescriptor) else {
      throw FontError.failedToCreateArrayTexture
    }

    // Populate texture
    let bytesPerPixel = 4
    for (index, var texture) in textures.enumerated() {
      let bytesPerRow = bytesPerPixel * texture.width
      let byteCount = bytesPerRow * texture.height

      arrayTexture.replace(
        region: MTLRegion(
          origin: MTLOrigin(x: 0, y: 0, z: 0),
          size: MTLSize(
            width: texture.width,
            height: texture.height,
            depth: 1
          )
        ),
        mipmapLevel: 0,
        slice: index,
        withBytes: &texture.bytes,
        bytesPerRow: bytesPerRow,
        bytesPerImage: byteCount
      )
    }

    return arrayTexture
  }

  /// Loads the characters descriptors from a bitmap font atlas.
  /// - Parameters:
  ///   - atlas: The bitmap font atlas.
  ///   - texture: The texture containing the characters.
  ///   - textureIndex: The index of the texture in the font's array texture.
  /// - Returns: The character descriptors.
  private static func descriptors(
    from atlas: BitmapFontProvider,
    texture: Texture,
    textureIndex: Int
  ) -> [Character: CharacterDescriptor] {
    var descriptors: [Character: CharacterDescriptor] = [:]
    for (yIndex, line) in atlas.characters.enumerated() {
      for (xIndex, character) in line.enumerated() {
        descriptors[character] = descriptor(
          for: character,
          xIndex: xIndex,
          yIndex: yIndex,
          texture: texture,
          textureIndex: textureIndex
        )
      }
    }
    return descriptors
  }

  /// Computes the descriptor for a character from a texture.
  /// - Parameters:
  ///   - character: The character to get the descriptor for.
  ///   - xIndex: The column the character is in (starting from 0).
  ///   - yIndex: The row the character is in (starting from 1).
  ///   - texture: The texture conatining the character.
  ///   - textureIndex: Tte texture's index.
  /// - Returns: A character descriptor.
  private static func descriptor(
    for character: Character,
    xIndex: Int,
    yIndex: Int,
    texture: Texture,
    textureIndex: Int
  ) -> CharacterDescriptor {
    var maxX = 0
    var minX = Self.defaultCharacterWidth
    var maxY = 0
    var minY = Self.defaultCharacterHeight
    for x in 0..<Self.defaultCharacterWidth {
      for y in 0..<Self.defaultCharacterHeight {
        let pixel = texture.getPixel(atX: x + xIndex * Self.defaultCharacterWidth, y: y + yIndex * Self.defaultCharacterHeight)
        if pixel.a != 0 {
          if x < minX {
            minX = x
          }
          if x > maxX {
            maxX = x
          }
          if y < minY {
            minY = y
          }
          if y > maxY {
            maxY = y
          }
        }
      }
    }
    if maxX < minX || maxY < minY {
      maxX = 0
      minX = 0
      maxY = 0
      minY = 0
    }
    var width = maxX - minX + 1
    let height = maxY - minY + 1

    // Hardcode width of space character
    if character == " " {
      width = 3
    }

    return CharacterDescriptor(
      texture: textureIndex,
      x: xIndex * Self.defaultCharacterWidth + minX,
      y: yIndex * Self.defaultCharacterHeight + minY,
      width: width,
      height: height,
      verticalOffset: Self.defaultCharacterHeight - maxY - 1
    )
  }
}
