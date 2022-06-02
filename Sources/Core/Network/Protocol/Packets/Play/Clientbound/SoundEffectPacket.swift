import Foundation

public struct SoundEffectPacket: ClientboundPacket {
  public static let id: Int = 0x51
  
  public var soundId: Int
  public var soundCategory: Int
  public var effectPositionX: Int
  public var effectPositionY: Int
  public var effectPositionZ: Int
  public var volume: Float
  public var pitch: Float

  public init(from packetReader: inout PacketReader) throws {
    soundId = try packetReader.readVarInt()
    soundCategory = try packetReader.readVarInt()
    effectPositionX = try packetReader.readInt()
    effectPositionY = try packetReader.readInt()
    effectPositionZ = try packetReader.readInt()
    volume = try packetReader.readFloat()
    pitch = try packetReader.readFloat()
  }
}
