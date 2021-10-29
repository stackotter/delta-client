import Foundation

public struct EntityEffectPacket: ClientboundPacket {
  public static let id: Int = 0x59
  
  public var entityId: Int
  public var effectId: Int8
  public var amplifier: Int8
  public var duration: Int
  public var flags: Int8

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    effectId = packetReader.readByte()
    amplifier = packetReader.readByte()
    duration = packetReader.readVarInt()
    flags = packetReader.readByte()
  }
}
