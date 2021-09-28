import Foundation

public struct EntityPositionPacket: ClientboundPacket {
  public static let id: Int = 0x28
  
  public var entityId: Int
  public var deltaX: Int16
  public var deltaY: Int16
  public var deltaZ: Int16
  public var onGround: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    deltaX = packetReader.readShort()
    deltaY = packetReader.readShort()
    deltaZ = packetReader.readShort()
    onGround = packetReader.readBool()
  }
}
