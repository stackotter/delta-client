import Foundation

public struct HeldItemChangePacket: ClientboundPacket {
  public static let id: Int = 0x3f
  
  public var slot: Int8
  
  public init(from packetReader: inout PacketReader) {
    slot = packetReader.readByte()
  }
  
  public func handle(for client: Client) throws {
    client.game.accessPlayer { player in
      player.inventory.hotbarSlot = Int(slot)
    }
  }
}
