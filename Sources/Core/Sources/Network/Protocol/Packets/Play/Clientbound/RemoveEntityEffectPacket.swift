import Foundation

public struct RemoveEntityEffectPacket: ClientboundPacket {
  public static let id: Int = 0x38
  
  public var entityId: Int
  public var effectId: Int8

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    effectId = packetReader.readByte()
  }
}
