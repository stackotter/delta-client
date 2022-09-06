import Metal
import simd

struct TextMeshBuilder {
  var font: Font

  func width(of text: String) throws -> Int {
    return try text.map { character in
      return try descriptor(for: character).width + 1
    }.reduce(0, +) - 1
  }

  func descriptor(for character: Character) throws -> CharacterDescriptor {
    guard let descriptor = font.characters[character] else {
      throw TextMeshBuilderError.invalidCharacter(character)
    }
    return descriptor
  }

  /// `indent` must be less than `maximumWidth` and `maximumWidth` must greater than the width of
  /// each individual character in the string.
  func wrap(_ text: String, maximumWidth: Int, indent: Int) throws -> [String] {
    assert(indent < maximumWidth, "indent must be smaller than maximumWidth")

    if text == "" {
      return [""]
    }

    var wrapIndex: String.Index? = nil
    var latestSpace: String.Index? = nil
    var width = 0
    for i in text.indices {
      let character = text[i]
      // TODO: Figure out how to load the rest of the characters (such as stars) from the font to
      // fix chat rendering on Hypixel
      let descriptor = try descriptor(for: character)
      assert(
        descriptor.width < maximumWidth,
        "maximumWidth must be greater than every individual character in the string"
      )

      width += descriptor.width
      if i != text.startIndex {
        width += 1 // character spacing
      }

      // TODO: wrap on other characters such as '-'
      if character == " " {
        latestSpace = i
      }

      if width > maximumWidth {
        if let spaceIndex = latestSpace {
          wrapIndex = spaceIndex
        } else {
          wrapIndex = i
        }
        break
      }
    }

    var lines: [String] = []
    if let wrapIndex = wrapIndex {
      lines = [String(text[text.startIndex..<wrapIndex])]

      var startIndex = wrapIndex
      while text[startIndex] == " " {
        startIndex = text.index(after: startIndex)
        if startIndex == text.endIndex {
          return lines // NOTE: early return
        }
      }
      let nonWrappedText = text[startIndex...]
      lines.append(contentsOf: try wrap(
        String(nonWrappedText),
        maximumWidth: maximumWidth - indent,
        indent: 0
      ))
    } else {
      lines = [text]
    }

    return lines
  }

  /// - Returns: `nil` if the input string is empty.
  func build(
    _ text: String,
    fontArrayTexture: MTLTexture,
    color: SIMD4<Float> = [1, 1, 1, 1],
    outlineColor: SIMD4<Float>? = nil
  ) throws -> GUIElementMesh? {
    if text.isEmpty {
      return nil
    }

    var currentX = 0
    let currentY = 0
    let spacing = 1
    var quads: [GUIQuad] = []
    for character in text {
      let descriptor = try descriptor(for: character)

      var quad = try Self.build(
        descriptor,
        fontArrayTexture: fontArrayTexture,
        color: color
      )
      quad.translate(amount: SIMD2([
        currentX,
        currentY
      ]))
      quads.append(quad)

      currentX += Int(quad.size.x) + spacing
    }

    guard !quads.isEmpty else {
      throw GUIRendererError.emptyText
    }

    // Create outline
    if let outlineColor = outlineColor {
      var outlineQuads: [GUIQuad] = []
      let outlineTranslations: [SIMD2<Float>] = [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ]

      for translation in outlineTranslations {
        for var quad in quads {
          quad.translate(amount: translation)
          quad.tint = outlineColor
          outlineQuads.append(quad)
        }
      }

      // Outline is rendered before the actual text
      quads = outlineQuads + quads
    }

    let width = currentX - spacing
    let height = Font.defaultCharacterHeight
    return GUIElementMesh(size: [width, height], arrayTexture: fontArrayTexture, quads: quads)
  }

  /// Creates a quad instance for the given character.
  private static func build(
    _ character: CharacterDescriptor,
    fontArrayTexture: MTLTexture,
    color: SIMD4<Float>
  ) throws -> GUIQuad {
    let arrayTextureWidth = Float(fontArrayTexture.width)
    let arrayTextureHeight = Float(fontArrayTexture.height)

    let position: SIMD2<Float> = [
      0,
      Float(Font.defaultCharacterHeight - character.height - character.verticalOffset)
    ]
    let size: SIMD2<Float> = [
      Float(character.width),
      Float(character.height)
    ]
    let uvMin: SIMD2<Float> = [
      Float(character.x) / arrayTextureWidth,
      Float(character.y) / arrayTextureHeight
    ]
    let uvSize: SIMD2<Float> = [
      Float(character.width) / arrayTextureWidth,
      Float(character.height) / arrayTextureHeight
    ]

    return GUIQuad(
      position: position,
      size: size,
      uvMin: uvMin,
      uvSize: uvSize,
      textureIndex: UInt16(character.texture),
      tint: color
    )
  }
}
