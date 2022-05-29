import Foundation

public struct EntitySoundEffectPacket: ClientboundPacket {
  public static let id: Int = 0x50
  
  public var soundId: Int
  public var soundCategory: Int
  public var entityId: Int
  public var volume: Float
  public var pitch: Float

  public init(from packetReader: inout PacketReader) throws {
    soundId = try packetReader.readVarInt()
    soundCategory = try packetReader.readVarInt()
    entityId = try packetReader.readVarInt()
    volume = try packetReader.readFloat()
    pitch = try packetReader.readFloat()
  }
}
