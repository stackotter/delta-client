import Foundation

public struct BlockBreakAnimationPacket: ClientboundPacket {
  public static let id: Int = 0x08

  public var entityId: Int
  public var location: BlockPosition
  public var destroyStage: Int8

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    location = try packetReader.readBlockPosition()
    destroyStage = try packetReader.readByte()
  }

  public func handle(for client: Client) throws {
    client.game.world.setBlockBreakingStage(at: location, to: Int(destroyStage), for: entityId)
  }
}
