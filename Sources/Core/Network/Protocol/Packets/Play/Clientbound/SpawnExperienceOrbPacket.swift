import Foundation

public struct SpawnExperienceOrbPacket: ClientboundPacket {
  public static let id: Int = 0x01
  
  public var entityId: Int
  public var position: SIMD3<Double>
  public var count: Int16
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    position = try packetReader.readEntityPosition()
    count = try packetReader.readShort()
  }
}
