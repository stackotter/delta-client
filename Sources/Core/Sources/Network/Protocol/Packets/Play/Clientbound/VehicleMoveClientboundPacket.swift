import Foundation

public struct VehicleMoveClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x2c
  
  public var position: EntityPosition
  public var yaw: Float
  public var pitch: Float
  
  public init(from packetReader: inout PacketReader) throws {
    position = packetReader.readEntityPosition()
    yaw = packetReader.readFloat()
    pitch = packetReader.readFloat()
  }
}
