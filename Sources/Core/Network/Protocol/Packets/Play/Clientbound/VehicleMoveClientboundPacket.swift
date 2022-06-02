import Foundation

public struct VehicleMoveClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x2c
  
  public var position: SIMD3<Double>
  public var yaw: Float
  public var pitch: Float
  
  public init(from packetReader: inout PacketReader) throws {
    position = try packetReader.readEntityPosition()
    yaw = try packetReader.readFloat()
    pitch = try packetReader.readFloat()
  }
}
