import Foundation

public struct StatusRequestPacket: ServerboundPacket {
  public static let id: Int = 0x00
  
  public func writePayload(to writer: inout PacketWriter) { }
}
