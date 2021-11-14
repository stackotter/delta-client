import Foundation

public struct PlayerPositionAndRotationServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x13
  
  public var position: SIMD3<Double> // y is feet position
  public var yaw: Float
  public var pitch: Float
  public var onGround: Bool
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeEntityPosition(position)
    writer.writeFloat(yaw)
    writer.writeFloat(pitch)
    writer.writeBool(onGround)
  }
}
