import Foundation

public struct EntityAnimationPacket: ClientboundPacket {
  public static let id: Int = 0x05
  
  public var entityId: Int
  public var animationId: UInt8
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    animationId = packetReader.readUnsignedByte()
  }
}
