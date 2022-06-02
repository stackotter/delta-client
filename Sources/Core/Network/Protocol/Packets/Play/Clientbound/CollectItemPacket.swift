import Foundation

public struct CollectItemPacket: ClientboundPacket {
  public static let id: Int = 0x55
  
  public var collectedEntityId: Int
  public var collectorEntityId: Int
  public var pickupItemCount: Int

  public init(from packetReader: inout PacketReader) throws {
    collectedEntityId = try packetReader.readVarInt()
    collectorEntityId = try packetReader.readVarInt()
    pickupItemCount = try packetReader.readVarInt()
  }
}
