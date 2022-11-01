import Foundation
import FirebladeMath

public struct VehicleMoveClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x2c

  public var position: Vec3d
  public var yaw: Float
  public var pitch: Float

  public init(from packetReader: inout PacketReader) throws {
    position = try packetReader.readEntityPosition()
    yaw = try packetReader.readFloat()
    pitch = try packetReader.readFloat()
  }
}
