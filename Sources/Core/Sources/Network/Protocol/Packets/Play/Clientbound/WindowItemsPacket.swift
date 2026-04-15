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
    client.game.accessPlayer { player in
      guard windowId == player.inventory.window.id else {
        return
      }

      guard slots.count == player.inventory.window.type.slotCount else {
        log.warning("Invalid player inventory slot count: \(slots.count)")
        // Silently ignore for now because Hypixel sends packets that violate this
        // TODO: Don't ignore invalid slot counts
        return
      }

      player.inventory.window.slots = slots
    }

    client.game.mutateGUIState { guiState in
      guard let window = guiState.window, windowId == window.id else {
        return
      }

      guard slots.count == window.type.slotCount else {
        log.warning("Invalid window slot count: \(slots.count)")
        return
      }

      window.slots = slots
    }
  }
}
