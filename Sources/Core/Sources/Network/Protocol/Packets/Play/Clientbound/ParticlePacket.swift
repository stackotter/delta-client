import Foundation

public struct ParticlePacket: ClientboundPacket {
  public static let id: Int = 0x23
  
  public var particleId: Int
  public var isLongDistance: Bool
  public var position: EntityPosition
  public var offsetX: Float
  public var offsetY: Float
  public var offsetZ: Float
  public var particleData: Float
  public var particleCount: Int

  public init(from packetReader: inout PacketReader) throws {
    particleId = packetReader.readInt()
    isLongDistance = packetReader.readBool()
    position = packetReader.readEntityPosition()
    offsetX = packetReader.readFloat()
    offsetY = packetReader.readFloat()
    offsetZ = packetReader.readFloat()
    particleData = packetReader.readFloat()
    particleCount = packetReader.readInt()
    
    // IMPLEMENT: there is also a data field but i really don't feel like decoding it rn
  }
}
