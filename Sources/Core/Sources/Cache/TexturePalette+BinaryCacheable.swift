import SwiftImage

extension TexturePalette: BinaryCacheable {
  public static var serializationFormatVersion: Int {
    return 0
  }

  public func serialize(into buffer: inout Buffer) {
    textures.serialize(into: &buffer)
    width.serialize(into: &buffer)
    height.serialize(into: &buffer)
    identifierToIndex.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> TexturePalette {
    return TexturePalette(
      textures: try .deserialize(from: &buffer),
      width: try .deserialize(from: &buffer),
      height: try .deserialize(from: &buffer),
      identifierToIndex: try .deserialize(from: &buffer)
    )
  }
}

extension Texture: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    type.serialize(into: &buffer)
    image.serialize(into: &buffer)
    animation.serialize(into: &buffer)
    frameCount.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Texture {
    return Texture(
      type: try .deserialize(from: &buffer),
      image: try .deserialize(from: &buffer),
      animation: try .deserialize(from: &buffer),
      frameCount: try .deserialize(from: &buffer)
    )
  }
}

extension Texture.BGRA: BitwiseCopyable {}

extension Image: BinarySerializable where Pixel: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    width.serialize(into: &buffer)
    height.serialize(into: &buffer)
    (width * height).serialize(into: &buffer) // Simplifies deserialization
    self.withUnsafeBytes { pixelBuffer in
      let pointer = pixelBuffer.assumingMemoryBound(to: UInt8.self).baseAddress!
      for i in 0..<pixelBuffer.count {
        buffer.writeByte(pointer.advanced(by: i).pointee)
      }
    }
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Self {
    return Self(
      width: try .deserialize(from: &buffer),
      height: try .deserialize(from: &buffer),
      pixels: try .deserialize(from: &buffer)
    )
  }
}

extension Texture.Animation: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    interpolate.serialize(into: &buffer)
    frames.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Texture.Animation {
    return Texture.Animation(
      interpolate: try .deserialize(from: &buffer),
      frames: try .deserialize(from: &buffer)
    )
  }
}

extension Texture.Animation.Frame: BitwiseCopyable {}
