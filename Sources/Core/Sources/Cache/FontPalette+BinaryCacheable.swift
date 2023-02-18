extension FontPalette: BinaryCacheable {
  public static var serializationFormatVersion: Int {
    return 0
  }

  public func serialize(into buffer: inout Buffer) {
    fonts.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> FontPalette {
    return FontPalette(try .deserialize(from: &buffer))
  }
}

extension Font: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    characters.serialize(into: &buffer)
    asciiCharacters.serialize(into: &buffer)
    textures.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Font {
    return Font(
      characters: try .deserialize(from: &buffer),
      asciiCharacters: try .deserialize(from: &buffer),
      textures: try .deserialize(from: &buffer)
    )
  }
}

extension CharacterDescriptor: BitwiseCopyable {}
