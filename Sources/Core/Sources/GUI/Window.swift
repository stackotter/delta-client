/// The slots behind a GUI window. Only a `class` because of the way it gets consumed by
/// ``InGameGUI``, it gets too unergonomic short of wrapping it in a ``Box`` (which
/// gets a little cumbersome sometimes, purely because we have to give inventory
/// special treatment while also wanting to work generically over mutable references to
/// windows).
public class Window {
  public var id: Int
  public var type: WindowType
  public var slots: [Slot]

  /// The action id to use for the next action performed on the inventory (used when sending
  /// ``ClickWindowPacket``).
  private var nextActionId = 0

  public init(id: Int, type: WindowType, slots: [Slot]? = nil) {
    if let count = slots?.count {
      precondition(count == type.slotCount)
    }

    self.id = id
    self.type = type
    self.slots = slots ?? Array(repeating: Slot(), count: type.slotCount)
    self.nextActionId = 0
  }

  /// Returns a unique window action id (counts up from 0 like vanilla does).
  private func generateActionId() -> Int16 {
    let id = nextActionId
    nextActionId += 1
    return Int16(id)
  }

  /// Gets the slots associated with a particular area of the window.
  /// - Returns: The rows of the area, e.g. ``PlayerInventory/hotbarArea`` results in a single row, and
  ///   ``PlayerInventory/armorArea`` results in 4 rows containing 1 element each.
  public func slots(for area: WindowArea) -> [[Slot]] {
    var rows: [[Slot]] = []
    for y in 0..<area.height {
      var row: [Slot] = []
      for x in 0..<area.width {
        let index = y * area.width + x + area.startIndex
        row.append(slots[index])
      }
      rows.append(row)
    }
    return rows
  }

  public func leftClick(_ slotIndex: Int, mouseStack: inout ItemStack?, connection: ServerConnection?) {
    let clickedItem = slots[slotIndex]
    if var slotStack = slots[slotIndex].stack,
        var mouseStackCopy = mouseStack,
        slotStack.itemId == mouseStackCopy.itemId
    {
      guard
        let item = RegistryStore.shared.itemRegistry.item(withId: slotStack.itemId)
      else {
        log.warning("Failed to get maximum stack size for item with id '\(slotStack.itemId)'")
        return
      }
      let total = slotStack.count + mouseStackCopy.count
      slotStack.count = min(total, item.maximumStackSize)
      slots[slotIndex].stack = slotStack
      if slotStack.count == total {
        mouseStack = nil
      } else {
        mouseStackCopy.count = total - slotStack.count
        mouseStack = mouseStackCopy
      }
    } else {
      swap(&slots[slotIndex].stack, &mouseStack)
    }
    do {
      try connection?.sendPacket(ClickWindowPacket(
        windowId: UInt8(id),
        actionId: generateActionId(),
        action: .leftClick(slot: Int16(slotIndex)),
        clickedItem: clickedItem
      ))
    } catch {
      log.warning("Failed to send click window packet for inventory left click: \(error)")
    }
  }

  public func rightClick(_ slotIndex: Int, mouseStack: inout ItemStack?, connection: ServerConnection?) {
    let clickedItem = slots[slotIndex]
    if var stack = slots[slotIndex].stack, mouseStack == nil {
      let total = stack.count
      var takenStack = stack
      stack.count = total / 2
      takenStack.count = total - stack.count
      mouseStack = takenStack
      if stack.count == 0 {
        slots[slotIndex].stack = nil
      } else {
        slots[slotIndex].stack = stack
      }
    } else if var stack = mouseStack, slots[slotIndex].stack == nil {
      stack.count -= 1
      slots[slotIndex].stack = ItemStack(itemId: stack.itemId, itemCount: 1)
      if stack.count == 0 {
        mouseStack = nil
      } else {
        mouseStack = stack
      }
    } else if let slotStack = slots[slotIndex].stack,
        slotStack.itemId == mouseStack?.itemId
    {
      slots[slotIndex].stack?.count += 1
      mouseStack?.count -= 1
      if mouseStack?.count == 0 {
        mouseStack = nil
      }
    } else {
      swap(&slots[slotIndex].stack, &mouseStack)
    }

    do {
      try connection?.sendPacket(ClickWindowPacket(
        windowId: UInt8(id),
        actionId: generateActionId(),
        action: .rightClick(slot: Int16(slotIndex)),
        clickedItem: clickedItem
      ))
    } catch {
      log.warning("Failed to send click window packet for inventory right click: \(error)")
    }
  }

  /// - Returns: `true` if the event was handled, otherwise `false` (indicating that the next relevant GUI
  ///   element should given the event, and so on).
  public func pressKey(
    over slotIndex: Int,
    event: KeyPressEvent,
    mouseStack: inout ItemStack?,
    inputState: InputState,
    connection: ServerConnection?
  ) -> Bool {
    guard let input = event.input else {
      return false
    }

    let slotInputs: [Input] = [.slot1, .slot2, .slot3, .slot4, .slot5, .slot6, .slot7, .slot8, .slot9]

    if input == .dropItem {
      guard mouseStack == nil else {
        return true
      }

      guard slots[slotIndex].stack?.count ?? 0 != 0 else {
        return true
      }

      let dropWholeStack = inputState.keys.contains(where: \.isControl)
      if dropWholeStack {
        dropStack(slotIndex, connection: connection)
      } else {
        dropItem(slotIndex, connection: connection)
      }
    } else if let hotBarSlot = slotInputs.firstIndex(of: input) {
      guard mouseStack == nil else {
        return true
      }

      let clickedItem = slots[slotIndex]
      let hotBarSlotslotIndex = PlayerInventory.hotbarArea.startIndex + hotBarSlot
      if hotBarSlotslotIndex != slotIndex {
        slots.swapAt(slotIndex, hotBarSlotslotIndex)
      }

      do {
        try connection?.sendPacket(ClickWindowPacket(
          windowId: UInt8(id),
          actionId: generateActionId(),
          action: .numberKey(slot: Int16(slotIndex), number: Int8(hotBarSlot)),
          clickedItem: clickedItem
        ))
      } catch {
        log.warning("Failed to send click window packet for inventory right click: \(error)")
      }
    } else {
      return false
    }

    return true
  }

  public func close(mouseStack: inout ItemStack?, eventBus: EventBus, connection: ServerConnection?) throws {
    mouseStack = nil
    eventBus.dispatch(CaptureCursorEvent())
    try connection?.sendPacket(CloseWindowServerboundPacket(windowId: UInt8(id)))
  }

  public func dropItem(_ slotIndex: Int, connection: ServerConnection?) {
    var dummy: ItemStack? = nil
    drop(slotIndex: slotIndex, wholeStack: false, mouseItemStack: &dummy, connection: connection)
  }

  public func dropStack(_ slotIndex: Int, connection: ServerConnection?) {
    var dummy: ItemStack? = nil
    drop(slotIndex: slotIndex, wholeStack: true, mouseItemStack: &dummy, connection: connection)
  }

  public func dropItemFromMouse(_ mouseStack: inout ItemStack?, connection: ServerConnection?) {
    drop(slotIndex: nil, wholeStack: false, mouseItemStack: &mouseStack, connection: connection)
  }

  public func dropStackFromMouse(_ mouseStack: inout ItemStack?, connection: ServerConnection?) {
    drop(slotIndex: nil, wholeStack: true, mouseItemStack: &mouseStack, connection: connection)
  }

  private func drop(
    slotIndex: Int?,
    wholeStack: Bool,
    mouseItemStack: inout ItemStack?,
    connection: ServerConnection?
  ) {
    let clickedItem = slotIndex.map { slots[$0] } ?? Slot(mouseItemStack)

    let dropCount = wholeStack ? clickedItem.stack?.count ?? 0 : 1
    if let index = slotIndex {
      slots[index].stack?.count -= dropCount
      if slots[index].stack?.count == 0 {
        slots[index].stack = nil
      }
    } else {
      mouseItemStack?.count -= dropCount
      if mouseItemStack?.count == 0 {
        mouseItemStack = nil
      }
    }

    let index = slotIndex.map(Int16.init)
    do {
      try connection?.sendPacket(ClickWindowPacket(
        windowId: UInt8(id),
        actionId: generateActionId(),
        action: wholeStack ? .dropStack(slot: index) : .dropOne(slot: index),
        clickedItem: clickedItem
      ))
    } catch {
      log.warning("Failed to send click window packet for item drop: \(error)")
    }
  }
}