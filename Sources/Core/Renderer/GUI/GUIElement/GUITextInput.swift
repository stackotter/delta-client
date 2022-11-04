import Foundation

struct GUITextInput: GUIElement {
  var content: String
  var width: Int

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    // Background
    let background = GUIRectangle(
      size: [width, 11],
      color: [0, 0, 0, 0.5]
    ).meshes(context: context)

    // Message
    var message = try content.meshes(context: context)
    message.translate(amount: [2, 2])

    // Cursor
    var cursor: [GUIElementMesh] = []
    if Int(CFAbsoluteTimeGetCurrent() * 10/3) % 2 == 1 {
      cursor = try "_".meshes(context: context)
      let messageWidth = message.size().x
      var xOffset = 2
      if messageWidth != 0 {
        xOffset = messageWidth + 4
      }
      cursor.translate(amount: [xOffset, 2])
    }

    return background + message + cursor
  }
}
