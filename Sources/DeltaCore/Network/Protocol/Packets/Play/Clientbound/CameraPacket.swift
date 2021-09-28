import Foundation

public struct CameraPacket: ClientboundPacket {
  public static let id: Int = 0x3e
  
  public var cameraEntityId: Int

  public init(from packetReader: inout PacketReader) throws {
    cameraEntityId = packetReader.readVarInt()
  }
}
