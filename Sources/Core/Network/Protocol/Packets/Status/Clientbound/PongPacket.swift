import Foundation

public struct PongPacket: ClientboundPacket {
  public static let id: Int = 0x01
  
  public var payload: Int
  
  public init(from packetReader: inout PacketReader) throws {
    payload = try packetReader.readLong()
  }
}
