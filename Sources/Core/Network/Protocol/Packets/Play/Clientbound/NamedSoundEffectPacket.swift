import Foundation

public struct NamedSoundEffectPacket: ClientboundPacket {
  public static let id: Int = 0x19
  
  public var soundName: Identifier
  public var soundCategory: Int
  public var effectPositionX: Int
  public var effectPositionY: Int
  public var effectPositionZ: Int
  public var volume: Float
  public var pitch: Float
  
  public init(from packetReader: inout PacketReader) throws {
    soundName = try packetReader.readIdentifier()
    soundCategory = packetReader.readVarInt()
    effectPositionX = packetReader.readInt()
    effectPositionY = packetReader.readInt()
    effectPositionZ = packetReader.readInt()
    volume = packetReader.readFloat()
    pitch = packetReader.readFloat()
  }
}
