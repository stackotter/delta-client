import FirebladeMath
import DeltaCore

struct GUIInventorySlot: GUIElement {
  var slot: Slot

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    guard let stack = slot.stack else {
      return []
    }

    // Starts in the upper left corner of the slot and extends 1 pixel further to the
    // right and downwards (due to the placement of the count text).
    var group = GUIGroupElement(Vec2i(17, 18))
    group.add(GUIInventoryItem(itemId: stack.itemId), .position(0, 0))

    if stack.count != 1 {
      // Drop shadow for the count
      group.add(
        GUIColoredString(String(stack.count), [62, 62, 62, 255] / 255),
        .bottom(0),
        .right(0)
      )

      group.add(String(stack.count), .bottom(1), .right(1))
    }

    return try group.meshes(context: context)
  }
}
