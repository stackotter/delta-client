import Foundation

public struct WindowItemsPacket: ClientboundPacket {
  public static let id: Int = 0x14

  public var windowId: UInt8
  public var slots: [Slot]

  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readUnsignedByte()

    slots = []
    let count = try packetReader.readShort()
    for _ in 0..<count {
      let slot = try packetReader.readSlot()
      slots.append(slot)
    }
  }

  public func handle(for client: Client) throws {
    guard windowId == PlayerInventory.windowId else {
      return
    }

    guard slots.count == PlayerInventory.slotCount else {
      log.warning("Invalid player inventory slot count: \(slots.count)")
      // Silently ignore for now because Hypixel sends packets that violate this
      // TODO: Don't ignore invalid slot counts
      return
    }

    client.game.accessPlayer { player in
      player.inventory.slots = slots
    }
  }
}
