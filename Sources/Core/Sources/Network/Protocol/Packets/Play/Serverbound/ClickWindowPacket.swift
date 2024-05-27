import Foundation

public struct ClickWindowPacket: ServerboundPacket {
  public static let id: Int = 0x09

  public var windowId: UInt8
  /// A unique id for the action, used by the server when sending confirmation packets.
  /// Vanilla computes this from per-window counters.
  public var actionId: Int16
  public var action: Action
  public var clickedItem: Slot

  public enum Action {
    case leftClick(slot: Int16)
    case rightClick(slot: Int16)
    case shiftLeftClick(slot: Int16)
    case shiftRightClick(slot: Int16)
    case numberKey(slot: Int16, number: Int8)
    case middleClick(slot: Int16)
    case drop(slot: Int16)
    case controlDrop(slot: Int16)
    case leftClickOutsideInventory
    case rightClickOutsideInventory
    case startLeftDrag
    case startRightDrag
    case startMiddleDrag
    case addLeftDragSlot(slot: Int16)
    case addRightDragSlot(slot: Int16)
    case addMiddleDragSlot(slot: Int16)
    case endLeftDrag
    case endRightDrag
    case endMiddleDrag
    case doubleClick(slot: Int16)

    var rawValue: (mode: Int32, button: Int8, slot: Int16?) {
      switch self {
        case let .leftClick(slot):
          return (0, 0, slot)
        case let .rightClick(slot):
          return (0, 1, slot)
        case let .shiftLeftClick(slot):
          return (1, 0, slot)
        case let .shiftRightClick(slot):
          return (1, 1, slot)
        case let .numberKey(slot, number):
          return (2, number, slot)
        case let .middleClick(slot):
          return (3, 2, slot)
        case let .drop(slot):
          return (4, 0, slot)
        case let .controlDrop(slot):
          return (4, 1, slot)
        case .leftClickOutsideInventory:
          return (4, 0, nil)
        case .rightClickOutsideInventory:
          return (4, 1, nil)
        case .startLeftDrag:
          return (5, 0, nil)
        case .startRightDrag:
          return (5, 4, nil)
        case .startMiddleDrag:
          return (5, 8, nil)
        case let .addLeftDragSlot(slot):
          return (5, 1, slot)
        case let .addRightDragSlot(slot):
          return (5, 5, slot)
        case let .addMiddleDragSlot(slot):
          return (5, 9, slot)
        case .endLeftDrag:
          return (5, 2, nil)
        case .endRightDrag:
          return (5, 6, nil)
        case .endMiddleDrag:
          return (5, 10, nil)
        case let .doubleClick(slot):
          return (6, 0, slot)
      }
    }
  }

  public func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(windowId)
    let (mode, button, slot) = action.rawValue
    writer.writeShort(slot ?? -999)
    writer.writeByte(button)
    writer.writeShort(actionId)
    writer.writeVarInt(mode)
    writer.writeSlot(clickedItem)
  }
}
