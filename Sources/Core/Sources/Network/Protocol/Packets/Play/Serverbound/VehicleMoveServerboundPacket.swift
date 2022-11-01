import Foundation
import FirebladeMath

public struct VehicleMoveServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x16

  public var position: Vec3d
  public var yaw: Float
  public var pitch: Float

  public func writePayload(to writer: inout PacketWriter) {
    writer.writeEntityPosition(position)
    writer.writeFloat(yaw)
    writer.writeFloat(pitch)
  }
}
