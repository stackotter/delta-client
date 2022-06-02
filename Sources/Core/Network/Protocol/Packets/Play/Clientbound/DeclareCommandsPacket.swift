import Foundation

public struct DeclareCommandsPacket: ClientboundPacket {
  public static let id: Int = 0x11
  
  public init(from packetReader: inout PacketReader) throws {
    // IMPLEMENT: declare commands packet
  }
}
