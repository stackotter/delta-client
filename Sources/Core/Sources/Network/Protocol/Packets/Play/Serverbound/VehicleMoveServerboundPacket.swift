import Foundation

public struct VehicleMoveServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x16
  
  public var position: SIMD3<Double>
  public var yaw: Float
  public var pitch: Float
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeEntityPosition(position)
    writer.writeFloat(yaw)
    writer.writeFloat(pitch)
  }
}
