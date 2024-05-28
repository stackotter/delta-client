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
  public func generateActionId() -> Int {
    let id = nextActionId
    nextActionId += 1
    return id
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
}
