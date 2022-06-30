import Foundation

public struct SetSlotPacket: ClientboundPacket {
  public static let id: Int = 0x16

  public var windowId: Int8
  public var slot: Int16
  public var slotData: Slot

  public init(from packetReader: inout PacketReader) throws {
    windowId = try packetReader.readByte()
    slot = try packetReader.readShort()
    slotData = try packetReader.readSlot()
  }

  public func handle(for client: Client) throws {
    let slot = Int(slot)
    let windowId = Int(windowId)

    guard slot >= 0 && slot < PlayerInventory.slotCount else {
      throw ClientboundPacketError.invalidInventorySlotIndex(slot, window: windowId)
    }

    // Only player inventory is handled at the moment
    guard slot == PlayerInventory.windowId || slot == -1 else {
      return
    }

    // If window id is 0, only hotbar slots can be sent (and should be animated)
    if windowId == 0 {
      guard slot >= PlayerInventory.hotbarSlotStartIndex && slot <= PlayerInventory.hotbarSlotEndIndex else {
        throw ClientboundPacketError.invalidInventorySlotIndex(slot, window: windowId)
      }
    }

    client.game.accessPlayer { player in
      player.inventory.slots[slot] = slotData
    }
  }
}
