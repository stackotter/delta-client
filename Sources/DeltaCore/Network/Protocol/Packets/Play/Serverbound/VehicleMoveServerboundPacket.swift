import Foundation

public struct VehicleMoveServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x16
  
  public var position: EntityPosition
  public var rotation: PlayerRotation
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeEntityPosition(position)
    writer.writeFloat(rotation.yaw)
    writer.writeFloat(rotation.pitch)
  }
}
