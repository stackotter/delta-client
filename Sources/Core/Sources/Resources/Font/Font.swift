import Foundation

/// An error related to fonts from resource packs.
public enum FontError: LocalizedError {
  case failedToGetArrayTextureWidth
  case failedToGetArrayTextureHeight
  case failedToCreateArrayTexture
  case emptyFont
  case invalidUnicodePageFileTemplate
  case invalidUnicodeScalar(page: Int, index: Int)

  public var errorDescription: String? {
    switch self {
      case .failedToGetArrayTextureWidth:
        return "Failed to get array texture width."
      case .failedToGetArrayTextureHeight:
        return "Failed to get array texture height."
      case .failedToCreateArrayTexture:
        return "Failed to create array texture."
      case .emptyFont:
        return "Empty font."
      case .invalidUnicodePageFileTemplate:
        return "Unicode page file path templates must be an identifier including exactly one occurence of '%s'."
      case let .invalidUnicodeScalar(page, index):
        return "Failed to create unicode scalar while loading legacy unicode font: page=\(page), index=\(index)."
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

  /// An internal initializer used to efficiently construct fonts from caches.
  init(
    characters: [Character: CharacterDescriptor],
    asciiCharacters: [CharacterDescriptor?],
    textures: [Texture]
  ) {
    self.characters = characters
    self.asciiCharacters = asciiCharacters
    self.textures = textures
  }

  /// Loads a font from a font manifest and texture directory.
  /// - Parameters:
  ///   - manifestFile: The font's manifest file.
  ///   - namespaceDirectory: The current resource namespace's root directory.
  ///   - textureDirectory: The resource pack's texture directory.
  /// - Throws: An error if texture or manifest loading fails.
  public static func load(from manifestFile: URL, namespaceDirectory: URL, textureDirectory: URL) throws -> Font {
    let manifest = try FontManifest.load(from: manifestFile)
    return try load(from: manifest, namespaceDirectory: namespaceDirectory, textureDirectory: textureDirectory)
  }

  /// Loads a font from a font manifest and texture directory.
  /// - Parameters:
  ///   - manifest: The font's manifest.
  ///   - namespaceDirectory: The current resource namespace's root directory.
  ///   - textureDirectory: The resource pack's texture directory.
  /// - Throws: An error if texture loading fails.
  public static func load(from manifest: FontManifest, namespaceDirectory: URL, textureDirectory: URL) throws -> Font {
    var characters: [Character: CharacterDescriptor] = [:]
    var textures: [Texture] = []

    for provider in manifest.providers {
      switch provider {
        case let .bitmap(atlas):
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
        case let .legacyUnicode(metadata):
          // TODO: These identifiers could be referring to resources in another namespace.
          //   We should support that instead of assuming that they're from the same namespace.
          //   This is probably a larger issue affecting a bunch of the resource hanling code,
          //   a generic way to get resource paths from identifiers is probably required.
          let glyphSizeFilePath = namespaceDirectory.appendingPathComponent(metadata.sizes.name)

          let pageFilePathTemplateParts = metadata.template.split(separator: ":")
          guard
            pageFilePathTemplateParts.count <= 2,
            let pageFilePathTemplate = pageFilePathTemplateParts.last
          else {
            throw FontError.invalidUnicodePageFileTemplate
          }

          guard
            pageFilePathTemplate.contains("%s"),
            pageFilePathTemplate.components(separatedBy: "%s").count <= 2
          else {
            throw FontError.invalidUnicodePageFileTemplate
          }

          for page in 0..<256 {
            let pageNumber = String(format: "%02x", page)
            let path = pageFilePathTemplate.replacingOccurrences(of: "%s", with: pageNumber)
            let textureFile = textureDirectory.appendingPathComponent(path)

            guard FileManager.default.fileExists(atPath: textureFile.path) else {
              continue
            }
            
            let texture = try Texture(pngFile: textureFile, type: .transparent)
            let textureIndex = textures.count
            textures.append(texture)

            for x in 0..<16 {
              for y in 0..<16 {
                let index = x + y * 16
                guard let unicodeScalar = UnicodeScalar(UInt16((page << 8) + index)) else {
                  throw FontError.invalidUnicodeScalar(page: page, index: index)
                }

                let character = Character(unicodeScalar)

                // The legacy unicode provider is just a fallback so it shouldn't override
                // characters from other fonts.
                guard characters[character] == nil else {
                  continue
                }

                characters[character] = CharacterDescriptor(
                  texture: textureIndex,
                  x: x * 16,
                  y: y * 16,
                  width: 16,
                  height: 16,
                  verticalOffset: 0,
                  scalingFactor: 0.5
                )
              }
            }
          }
        case .trueType:
          continue
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
        let pixel = texture[
          x + xIndex * Self.defaultCharacterWidth,
          y + yIndex * Self.defaultCharacterHeight
        ]

        if pixel.alpha != 0 {
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
      verticalOffset: Self.defaultCharacterHeight - maxY - 1,
      scalingFactor: 1
    )
  }
}
