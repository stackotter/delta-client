import Foundation

public struct UpdateViewDistancePacket: ClientboundPacket {
  public static let id: Int = 0x41
  
  public var viewDistance: Int

  public init(from packetReader: inout PacketReader) throws {
    viewDistance = packetReader.readVarInt()
  }
}
