import Foundation

public struct DestroyEntitiesPacket: ClientboundPacket {
  public static let id: Int = 0x37
  
  public var entityIds: [Int]

  public init(from packetReader: inout PacketReader) throws {
    entityIds = []
    let count = packetReader.readVarInt()
    for _ in 0..<count {
      let entityId = packetReader.readVarInt()
      entityIds.append(entityId)
    }
  }
}
