import Foundation

public struct PingPacket: ServerboundPacket {
  public static let id: Int = 0x01
  
  public var payload: Int
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeLong(Int64(payload))
  }
}
