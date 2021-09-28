import Foundation

public struct PlayerRotationPacket: ServerboundPacket {
  public static let id: Int = 0x14
  
  public var rotation: PlayerRotation
  public var onGround: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeFloat(rotation.yaw)
    writer.writeFloat(rotation.pitch)
    writer.writeBool(onGround)
  }
}
