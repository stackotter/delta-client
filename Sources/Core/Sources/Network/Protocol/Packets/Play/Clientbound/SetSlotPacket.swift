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

    // Only player inventory is handled at the moment
    guard windowId == PlayerInventory.windowId || windowId == -2 else {
      return
    }

    // Check for out-of-bounds
    guard slot >= 0 && slot < PlayerInventory.slotCount else {
      throw ClientboundPacketError.invalidInventorySlotIndex(slot, windowId: windowId)
    }

    // If window id is 0, only hotbar slots can be sent (and should be animated)
    // if windowId == 0 {
    //   guard slot >= PlayerInventory.hotbarSlotStartIndex && slot <= PlayerInventory.hotbarSlotEndIndex else {
    //     throw ClientboundPacketError.invalidInventorySlotIndex(slot, window: windowId)
    //   }
    // }
    // TODO: Figure out why this fails when joining servers like Hypixel

    client.game.accessPlayer { player in
      if Int(windowId) == player.inventory.window.id {
        player.inventory.window.slots[slot] = slotData
      }
    }

    client.game.mutateGUIState { guiState in
      if let window = guiState.window, Int(windowId) == window.id {
        window.slots[slot] = slotData
      }
    }
  }
}
