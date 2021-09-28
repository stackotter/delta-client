import Foundation

public protocol ServerboundPacket {
  static var id: Int { get }
  
  // writes payload to packetwriter (everything after packet id)
  func writePayload(to writer: inout PacketWriter)
}

extension ServerboundPacket {
  public func toBuffer() -> Buffer {
    var writer = PacketWriter()
    writer.writeVarInt(Int32(Self.id))
    writePayload(to: &writer)
    return writer.buffer
  }
}
