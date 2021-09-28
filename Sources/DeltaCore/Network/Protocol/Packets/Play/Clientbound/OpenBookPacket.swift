import Foundation

public struct OpenBookPacket: ClientboundPacket {
  public static let id: Int = 0x2d
  
  public var hand: Int
  
  public init(from packetReader: inout PacketReader) throws {
    hand = packetReader.readVarInt()
  }
}
