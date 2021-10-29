import Foundation

public struct SetCooldownPacket: ClientboundPacket {
  public static let id: Int = 0x17
  
  public var itemId: Int
  public var cooldownTicks: Int
  
  public init(from packetReader: inout PacketReader) throws {
    itemId = packetReader.readVarInt()
    cooldownTicks = packetReader.readVarInt()
  }
}
