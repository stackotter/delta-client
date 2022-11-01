import Foundation
import FirebladeMath

public struct ParticlePacket: ClientboundPacket {
  public static let id: Int = 0x23

  public var particleId: Int
  public var isLongDistance: Bool
  public var position: Vec3d
  public var offsetX: Float
  public var offsetY: Float
  public var offsetZ: Float
  public var particleData: Float
  public var particleCount: Int

  public init(from packetReader: inout PacketReader) throws {
    particleId = try packetReader.readInt()
    isLongDistance = try packetReader.readBool()
    position = try packetReader.readEntityPosition()
    offsetX = try packetReader.readFloat()
    offsetY = try packetReader.readFloat()
    offsetZ = try packetReader.readFloat()
    particleData = try packetReader.readFloat()
    particleCount = try packetReader.readInt()

    // TODO: there is also a data field but i really don't feel like decoding it rn
  }
}
