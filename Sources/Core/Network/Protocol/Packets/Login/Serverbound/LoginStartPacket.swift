import Foundation

public struct LoginStartPacket: ServerboundPacket {
  public static let id: Int = 0x00
  
  public var username: String
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeString(username)
  }
}
