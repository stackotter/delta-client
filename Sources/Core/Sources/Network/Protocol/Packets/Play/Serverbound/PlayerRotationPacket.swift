import Foundation

public struct PlayerRotationPacket: ServerboundPacket {
  public static let id: Int = 0x14
  
  public var yaw: Float
  public var pitch: Float
  public var onGround: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeFloat(yaw)
    writer.writeFloat(pitch)
    writer.writeBool(onGround)
  }
}
