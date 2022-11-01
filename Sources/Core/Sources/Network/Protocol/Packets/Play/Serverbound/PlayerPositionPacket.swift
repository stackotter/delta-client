import Foundation
import FirebladeMath

public struct PlayerPositionPacket: ServerboundPacket {
  public static let id: Int = 0x12

  public var position: Vec3d // Position of feet
  public var onGround: Bool

  public func writePayload(to writer: inout PacketWriter) {
    writer.writeEntityPosition(position)
    writer.writeBool(onGround)
  }
}
