import Foundation

public struct PluginMessageServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x0b
  
  public var channel: Identifier
  public var data: [UInt8]
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeIdentifier(channel)
    writer.writeByteArray(data)
  }
}
