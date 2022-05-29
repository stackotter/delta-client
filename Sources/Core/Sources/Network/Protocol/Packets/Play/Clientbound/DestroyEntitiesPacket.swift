/// Removes entities from the game (either dead or disconnected or outside render distance).
public struct DestroyEntitiesPacket: ClientboundPacket {
  public static let id: Int = 0x37
  
  public var entityIds: [Int]

  public init(from packetReader: inout PacketReader) throws {
    entityIds = []
    let count = try packetReader.readVarInt()
    for _ in 0..<count {
      let entityId = try packetReader.readVarInt()
      entityIds.append(entityId)
    }
  }
  
  public func handle(for client: Client) throws {
    for entityId in entityIds {
      client.game.removeEntity(id: entityId)
    }
  }
}
